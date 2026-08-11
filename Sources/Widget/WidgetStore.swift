import Foundation
import SwiftData

// Widget 端的讀取入口。extension 是獨立 process，開自己的連線讀同一份 store
// （persistence spec:「An extension SHALL open its own connection to that store」）。
//
// ⚠️ 不指定 configuration name / url / groupContainer identifier——
// groupContainer 預設即為 .automatic，會依 entitlement 找到共用容器；
// 明確指定會繞過偵測而開出空 store（persistence spec:「The store location is
// never specified explicitly once an app group is adopted」）。
enum WidgetStore {
    /// 讀取失敗一律回空 summary，不丟錯、不終止——
    /// Widget 崩潰在使用者眼中是一塊空白磚，比顯示「目前沒有食材」更糟。
    ///
    /// 刻意不綁 MainActor：timeline 產生於背景，改用自建的 `ModelContext`
    /// 而非 `mainContext`（後者是 @MainActor，會讓 completion 跨 actor 傳遞
    /// 而觸發 Swift 6 的 data race 檢查）。
    static func loadSummary(today: Date = .now) -> FoodStatusSummary {
        guard let container = try? ModelContainer(for: FoodItemEntity.self) else {
            return FoodStatusSummary(active: [], today: today)
        }
        let context = ModelContext(container)

        let activeRaw = RecordStatus.active.rawValue
        var descriptor = FetchDescriptor<FoodItemEntity>(
            predicate: #Predicate { $0.statusRaw == activeRaw },
            sortBy: [SortDescriptor(\.expiryDate, order: .forward)]
        )
        // Widget 只顯示彙總數字，不逐筆列出——圖片是這個 store 裡最大的欄位，
        // 不讀進來可省下可觀的記憶體（extension 的額度遠低於 app）。
        descriptor.propertiesToFetch = [\.expiryDate, \.price, \.statusRaw]

        guard let entities = try? context.fetch(descriptor) else {
            return FoodStatusSummary(active: [], today: today)
        }
        return FoodStatusSummary(active: entities.map { $0.toDomain() }, today: today)
    }
}
