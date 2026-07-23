import Foundation

// MARK: - State

extension AnalyticsViewModel {
    struct State: Equatable, Sendable {
        // 現況（active 三桶）
        var expired: [FoodItem] = []      // 已過期未處理
        var nearExpiry: [FoodItem] = []   // 3 天內到期
        var fresh: [FoodItem] = []        // 保存期限內

        // 歷史統計（已處理）
        var consumedCount: Int = 0        // 吃掉（近 30 天視窗）
        var wastedCount: Int = 0          // 丟棄（近 30 天視窗）
        var hasHistory: Bool = false      // 是否有「任何」已處理紀錄（all-time，決定清除鈕是否露出）
        var showClearHistoryConfirm: Bool = false

        var activeTotal: Int { expired.count + nearExpiry.count + fresh.count }
        var resolvedTotal: Int { consumedCount + wastedCount }

        /// 浪費率 = 丟棄 /（吃掉 + 丟棄）。無資料時為 nil。
        var wasteRate: Double? {
            resolvedTotal == 0 ? nil : Double(wastedCount) / Double(resolvedTotal)
        }
    }
}
