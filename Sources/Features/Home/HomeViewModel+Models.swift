import Foundation

// MARK: - State

extension HomeViewModel {
    struct State: Equatable, Sendable {
        // 現況：active 依效期分三桶（各桶內依到期日升冪）
        var expired: [FoodItem] = []          // 已過期未處理
        var nearExpiry: [FoodItem] = []       // 3 天內到期
        var fresh: [FoodItem] = []            // 保存期限內

        // 廣告 / 互動流程
        var adsRemoved: Bool = false          // 由 IAP entitlement 驅動
        var pendingDeleteItem: FoodItem? = nil // 刪除確認對象（非 nil → 顯示確認）
        var extendingItem: FoodItem? = nil     // 延長 date picker 對象（非 nil → 顯示 picker）

        // 浪費統計（近 30 天視窗）
        var consumedCount: Int = 0            // 吃掉
        var wastedCount: Int = 0              // 丟棄
        var hasHistory: Bool = false          // all-time 是否有已處理紀錄（決定清除鈕露出）
        var showClearHistoryConfirm: Bool = false

        /// 全部 active（急→緩），供通知排程與空狀態判斷。
        var items: [FoodItem] { expired + nearExpiry + fresh }
        var activeTotal: Int { expired.count + nearExpiry.count + fresh.count }
        var resolvedTotal: Int { consumedCount + wastedCount }
        var isEmpty: Bool { activeTotal == 0 }

        /// 浪費率 = 丟棄 /（吃掉 + 丟棄）。無資料時為 nil。
        var wasteRate: Double? {
            resolvedTotal == 0 ? nil : Double(wastedCount) / Double(resolvedTotal)
        }
    }
}
