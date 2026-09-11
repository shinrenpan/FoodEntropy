import AppIntents
import CoreSpotlight
import Foundation

// 食材的 Spotlight 語義索引（見 app-intents、決策七）。
//
// 以「整批重建」而非逐筆增刪同步，與 `notification` 的排程對帳同一個理由：
// 追蹤個別變動遲早會漏掉一條路徑，而本專案的資料量（個人庫存，數十筆）
// 讓整批重建的成本可以忽略。
//
// 失敗一律吞掉：索引不進去只是搜尋找不到，不該讓一次存檔失敗。
enum FoodItemSpotlightIndex {

    static func reindex(active items: [FoodItem]) async {
        let index = CSSearchableIndex.default()
        do {
            // 先清空再寫入——已使用／丟棄／刪除的食材要從索引消失，
            // 而它們不會出現在 `items` 裡，只靠寫入無法移除。
            try await index.deleteAppEntities(ofType: FoodItemAppEntity.self)
            try await index.indexAppEntities(items.map(FoodItemAppEntity.init(item:)))
        } catch {
            // Release 仍然靜默：索引不進去只是搜尋找不到，不該影響存檔。
            // Debug 留下線索——否則「Spotlight 搜不到」分不清是索引失敗還是尚未建立。
            #if DEBUG
            print("[Spotlight] reindex failed: \(error)")
            #endif
        }
    }
}
