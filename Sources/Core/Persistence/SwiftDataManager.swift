import Foundation
import SwiftData

// 資料層邊界（02-architecture §1 §4 §6）。
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
            configuration = ModelConfiguration(
                cloudKitDatabase: cloudKitEnabled ? .automatic : .none
            )
        }
        container = try ModelContainer(for: FoodItemEntity.self, configurations: configuration)
    }

    // MARK: - Read

    /// 現存（active）食材，依到期日升冪、次序 createdAt 升冪（03-screens/home.md）。
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

    // MARK: - Create

    @discardableResult
    func create(
        name: String,
        purchaseDate: Date,
        expiryDate: Date,
        imageData: Data? = nil
    ) -> FoodItem {
        let entity = FoodItemEntity(
            name: name,
            purchaseDate: purchaseDate,
            expiryDate: expiryDate,
            imageData: imageData
        )
        context.insert(entity)
        save()
        return entity.toDomain()
    }

    // MARK: - Update

    func update(
        id: UUID,
        name: String,
        purchaseDate: Date,
        expiryDate: Date,
        imageData: Data?
    ) {
        guard let entity = entity(for: id) else { return }
        entity.name = name
        entity.purchaseDate = purchaseDate
        entity.expiryDate = expiryDate
        entity.imageData = imageData
        save()
    }

    // MARK: - Status transitions

    func markConsumed(id: UUID) { resolve(id: id, to: .consumed) }

    func markWasted(id: UUID) { resolve(id: id, to: .wasted) }

    /// Hard delete（誤加 / 打錯用，不留紀錄）。
    func delete(id: UUID) {
        guard let entity = entity(for: id) else { return }
        context.delete(entity)
        save()
    }

    // MARK: - Private

    private func resolve(id: UUID, to status: RecordStatus) {
        guard let entity = entity(for: id) else { return }
        entity.statusRaw = status.rawValue
        entity.resolvedAt = .now
        save()
    }

    private func entity(for id: UUID) -> FoodItemEntity? {
        var descriptor = FetchDescriptor<FoodItemEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func save() {
        do {
            try context.save()
        } catch {
            assertionFailure("SwiftDataManager save failed: \(error)")
        }
    }
}
