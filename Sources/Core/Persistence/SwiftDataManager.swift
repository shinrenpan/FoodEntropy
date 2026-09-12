import Foundation
import SwiftData
import WidgetKit

// 資料層邊界（見 persistence）。
// - 持有 ModelContainer / mainContext
// - CRUD 只回傳 Domain（呼叫 toDomain()），絕不外洩 @Model
// - container 依「iCloud 開關」偏好決定掛不掛 cloudKitDatabase（啟動時決定、重啟才變更）
@MainActor
final class SwiftDataManager {
    private let container: ModelContainer

    private var context: ModelContext { container.mainContext }

    /// - Parameters:
    ///   - cloudKitEnabled: 是否掛 CloudKit 同步（來自使用者 opt-in 偏好）。
    ///   - inMemory: 測試用記憶體儲存。
    init(cloudKitEnabled: Bool = false, inMemory: Bool = false) throws {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        } else {
            // 首次啟動時 Application Support 目錄尚不存在，CoreData 會先報錯再自行復原
            // （產生一大串嚇人的 log）。預先建立可消除該噪音、也更穩健。
            try? FileManager.default.createDirectory(
                at: URL.applicationSupportDirectory,
                withIntermediateDirectories: true
            )
            configuration = ModelConfiguration(
                cloudKitDatabase: cloudKitEnabled ? .automatic : .none
            )
        }
        container = try ModelContainer(for: FoodItemEntity.self, configurations: configuration)
    }

    /// 資料變動廣播。App Intents 與畫面同在 app process，因此 in-process 的
    /// NotificationCenter 就夠——不必依賴前景／背景轉換。
    /// iOS 27 可在 app 前景直接下拉 Spotlight 執行動作，那條路徑**沒有**
    /// 生命週期轉換可依附（2026-09-11 實機發現）。
    static let didChangeNotification = Notification.Name("SwiftDataManagerDidChange")

    // MARK: - Process 層級取用點

    /// 整個 app process 共用的單一連線。
    ///
    /// App Intents 的 `perform()` 可能在 app 未啟動、或啟動至背景而無 scene 時執行，
    /// 取不到 `SceneDelegate` 持有的實例。若各自建立，同一 process 內會出現兩個
    /// `ModelContainer` 指向同一份 store——Intent 的寫入不會反映到畫面既有的 context。
    /// 故統一由此取用（見 persistence:「The store is reachable from a process-level accessor」）。
    ///
    /// 偏好於首次存取時讀取一次，而 process 生命週期即為「一次啟動」，
    /// 因此 `icloud-sync` 的「下次啟動生效」語意不變。
    static let shared: SwiftDataManager = {
        let cloudKitEnabled = UserDefaults.standard.bool(forKey: AppPreferenceKey.iCloudSyncEnabled)
        return makeResilient(cloudKitEnabled: cloudKitEnabled)
    }()

    // MARK: - Resilient factory

    /// 依序嘗試建立，第一個成功者勝出；全失敗回 nil。純函式，供測試注入失敗閉包。
    static func firstSuccess(_ attempts: [() throws -> SwiftDataManager]) -> SwiftDataManager? {
        for attempt in attempts {
            if let manager = try? attempt() { return manager }
        }
        return nil
    }

    /// 三層優雅降級：正常（可能含 CloudKit）→ local-only → in-memory。
    /// 把 `ModelContainer` 建立失敗（遷移/ CloudKit / 磁碟）從「launch crash loop」
    /// 降成「最差也開得起來」：CloudKit 出錯退純本機，本機也壞退記憶體（該次不落地但不崩）。
    static func makeResilient(cloudKitEnabled: Bool) -> SwiftDataManager {
        var attempts: [() throws -> SwiftDataManager] = [
            { try SwiftDataManager(cloudKitEnabled: cloudKitEnabled) },
        ]
        if cloudKitEnabled {
            // 第一層失敗多半是 CloudKit 惹禍 → 退成純本機儲存（資料仍在本機）。
            attempts.append { try SwiftDataManager(cloudKitEnabled: false) }
        }
        // 最後防線：連本機儲存都建不起來（磁碟滿/損毀）→ 記憶體版，保證能啟動。
        attempts.append { try SwiftDataManager(inMemory: true) }

        if let manager = firstSuccess(attempts) { return manager }
        // in-memory 幾乎不可能失敗；真到這裡代表環境徹底異常，無從復原。
        fatalError("SwiftDataManager 三層降級全數失敗")
    }

    // MARK: - Read

    /// 現存（active）食材，依到期日升冪、次序 createdAt 升冪（見 persistence 的查詢排序契約）。
    func fetchActiveFoods() -> [FoodItem] {
        let activeRaw = RecordStatus.active.rawValue
        let descriptor = FetchDescriptor<FoodItemEntity>(
            predicate: #Predicate { $0.statusRaw == activeRaw },
            sortBy: [
                SortDescriptor(\.expiryDate, order: .forward),
                SortDescriptor(\.createdAt, order: .forward),
            ]
        )
        let entities = (try? context.fetch(descriptor)) ?? []
        return entities.map { $0.toDomain() }
    }

    /// 與 `fetchActiveFoods()` 相同的結果與排序，但**不載入 `imageData`**。
    /// 供 App Intents 的 entity query 使用——entity 不含圖片，逐列標註時
    /// 每列都載入 JPEG 會讓系統的 payload 索取逾時。
    /// 作法與 `WidgetStore` 一致（`propertiesToFetch` 避開大欄位）。
    func fetchActiveFoodsWithoutImages() -> [FoodItem] {
        let activeRaw = RecordStatus.active.rawValue
        var descriptor = FetchDescriptor<FoodItemEntity>(
            predicate: #Predicate { $0.statusRaw == activeRaw },
            sortBy: [
                SortDescriptor(\.expiryDate, order: .forward),
                SortDescriptor(\.createdAt, order: .forward),
            ]
        )
        descriptor.propertiesToFetch = [\.id, \.name, \.purchaseDate, \.expiryDate, \.statusRaw, \.createdAt, \.price]
        let entities = (try? context.fetch(descriptor)) ?? []
        return entities.map { $0.toDomainWithoutImage() }
    }

    /// 已處理（consumed / wasted）食材，依 resolvedAt 由新到舊。供首頁的浪費統計用。
    func fetchResolvedFoods() -> [FoodItem] {
        let activeRaw = RecordStatus.active.rawValue
        let descriptor = FetchDescriptor<FoodItemEntity>(
            predicate: #Predicate { $0.statusRaw != activeRaw },
            sortBy: [SortDescriptor(\.resolvedAt, order: .reverse)]
        )
        let entities = (try? context.fetch(descriptor)) ?? []
        return entities.map { $0.toDomain() }
    }

    // MARK: - Create

    @discardableResult
    func create(
        name: String,
        purchaseDate: Date,
        expiryDate: Date,
        imageData: Data? = nil,
        price: Double? = nil
    ) throws -> FoodItem {
        let entity = FoodItemEntity(
            name: name,
            purchaseDate: purchaseDate,
            expiryDate: expiryDate,
            imageData: imageData,
            price: price
        )
        context.insert(entity)
        try save()
        return entity.toDomain()
    }

    // MARK: - Update

    /// - Parameter price: 刻意不給預設值——有預設值時，忘記傳的呼叫端（如首頁「延長效期」）
    ///   會靜默把既有價格清成 nil。無預設值讓編譯器強制每個呼叫端明示意圖。
    func update(
        id: UUID,
        name: String,
        purchaseDate: Date,
        expiryDate: Date,
        imageData: Data?,
        price: Double?
    ) throws {
        guard let entity = entity(for: id) else { return }
        entity.name = name
        entity.purchaseDate = purchaseDate
        entity.expiryDate = expiryDate
        entity.imageData = imageData
        entity.price = price
        try save()
    }

    // MARK: - Status transitions

    func markConsumed(id: UUID) throws { try resolve(id: id, to: .consumed) }

    func markWasted(id: UUID) throws { try resolve(id: id, to: .wasted) }

    /// Hard delete（誤加 / 打錯用，不留紀錄）。
    func delete(id: UUID) throws {
        guard let entity = entity(for: id) else { return }
        context.delete(entity)
        try save()
    }

    // MARK: - Private

    private func resolve(id: UUID, to status: RecordStatus) throws {
        guard let entity = entity(for: id) else { return }
        entity.statusRaw = status.rawValue
        entity.resolvedAt = .now
        entity.imageData = nil   // 已離開清單，圖片不再需要 → 剝離以省本機 / iCloud 空間
        try save()
    }

    /// 清除所有已處理（consumed / wasted）紀錄。供設定「清除歷史統計」。
    func deleteResolvedFoods() throws {
        let activeRaw = RecordStatus.active.rawValue
        let descriptor = FetchDescriptor<FoodItemEntity>(
            predicate: #Predicate { $0.statusRaw != activeRaw }
        )
        let entities = (try? context.fetch(descriptor)) ?? []
        for entity in entities {
            context.delete(entity)
        }
        try save()
    }

    private func entity(for id: UUID) -> FoodItemEntity? {
        var descriptor = FetchDescriptor<FoodItemEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    /// 寫入失敗時丟出。
    ///
    /// 過去是 `assertionFailure` 後吞掉——而它在 **Release 是 no-op**，
    /// 等於靜默失敗。App Intents 會據此對使用者回報成功（Siri 唸出「已標記」
    /// 而資料沒落地），比 app 內更糟：app 內至少看得到清單沒變。
    ///
    /// 事後重新查詢無法代替錯誤傳遞——`context.save()` 失敗時，同一個 context
    /// 仍會回傳記憶體中未落地的變更，驗證會誤判成功。
    private func save() throws {
        do {
            try context.save()
            // Widget 讀的是同一份 store，但 iOS 不會主動通知它資料變了。
            // 放在這裡而非各 ViewModel：這是所有寫入的單一出口，
            // 分散到呼叫端遲早會漏掉一條路徑（widget spec:「SHALL request a
            // reload when items are added, resolved, or deleted」）。
            // 沒有 widget 時為 no-op，故不需條件判斷。
            WidgetCenter.shared.reloadAllTimelines()
            // Spotlight 索引同理：同一個「資料變了要通知誰」的出口，
            // 散到各呼叫端必漏（見 app-intents 決策七）。
            let active = fetchActiveFoods()
            Task { await FoodItemSpotlightIndex.reindex(active: active) }
            // 同一個出口再廣播給畫面（見 app-intents 決策八）。
            NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
        } catch {
            assertionFailure("SwiftDataManager save failed: \(error)")   // DEBUG 仍立即現形
            throw error
        }
    }
}
