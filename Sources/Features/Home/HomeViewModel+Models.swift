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

        // 金額（add-price-tracking）。nil = 無可計算金額 → 該行整行不渲染，不顯示 0。
        var upcomingExpiryCost: Double? = nil  // 前瞻：nearExpiry 桶中已記錄價格者的總和
        var wastedCost: Double? = nil          // 回顧：統計視窗內已丟棄且已記錄價格者的總和
        var expiredCost: Double? = nil         // SPIKE：過期桶的金額，供堆疊卡顯示

        // SPIKE v7（experiment/home-card-stack）：五張卡一疊。
        // Current／Waste 是摘要卡，點了只是移到前面；三張分桶卡點了會開 sheet。
        var selectedCard: HomeCard = .expired
        /// 非 nil 時呈現該分桶的完整清單 sheet（真正的 List，四個手勢都在）。
        var sheetBucket: ExpiryStatus? = nil

        func items(in bucket: ExpiryStatus) -> [FoodItem] {
            switch bucket {
            case .expired: expired
            case .nearExpiry: nearExpiry
            case .fresh: fresh
            }
        }

        /// 最急迫且非空的分桶；全空時回 expired。
        var mostUrgentNonEmptyBucket: ExpiryStatus {
            if !expired.isEmpty { return .expired }
            if !nearExpiry.isEmpty { return .nearExpiry }
            if !fresh.isEmpty { return .fresh }
            return .expired
        }

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

// MARK: - HomeCard（SPIKE v7）

/// 首頁那疊卡的身分。前兩張是摘要，後三張是分桶。
enum HomeCard: Hashable, Sendable, CaseIterable {
    case current
    case waste
    case expired
    case nearExpiry
    case fresh

    /// 分桶卡對應的效期狀態；摘要卡為 nil。
    var bucket: ExpiryStatus? {
        switch self {
        case .current, .waste: nil
        case .expired: .expired
        case .nearExpiry: .nearExpiry
        case .fresh: .fresh
        }
    }
}
