import Foundation

// MARK: - State

extension HomeViewModel {
    struct State: Equatable, Sendable {
        var items: [FoodItem] = []            // active，已排序（expiryDate↑, createdAt↑）
        var adsRemoved: Bool = false          // v1 寫死 false；Phase 8 由 IAP entitlement 驅動
        var pendingDeleteItem: FoodItem? = nil // 刪除確認對象（非 nil → 顯示確認）
        var extendingItem: FoodItem? = nil     // 延長 date picker 對象（非 nil → 顯示 picker）

        var isEmpty: Bool { items.isEmpty }
    }
}
