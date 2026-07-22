import Foundation

// MARK: - State

extension AnalyticsViewModel {
    struct State: Equatable, Sendable {
        var expired: [FoodItem] = []      // 已過期未處理
        var nearExpiry: [FoodItem] = []   // 3 天內到期
        var fresh: [FoodItem] = []        // 保存期限內
    }
}
