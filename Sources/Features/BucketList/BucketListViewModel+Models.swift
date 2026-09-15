import Foundation

// MARK: - State

extension BucketListViewModel {
    struct State: Equatable, Sendable {
        /// 該桶的食材，順序沿用資料層（到期日升冪，見 persistence 的查詢排序契約）。
        var items: [FoodItem] = []
        var pendingDeleteItem: FoodItem? = nil  // 刪除確認對象（非 nil → 顯示確認）
        var extendingItem: FoodItem? = nil      // 延長 date picker 對象（非 nil → 顯示 picker）

        var isEmpty: Bool { items.isEmpty }
    }
}
