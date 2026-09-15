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

        // 浪費統計（近 30 天視窗）
        var consumedCount: Int = 0            // 吃掉
        var wastedCount: Int = 0              // 丟棄
        var hasHistory: Bool = false          // all-time 是否有已處理紀錄（決定清除鈕露出）
        var showClearHistoryConfirm: Bool = false

        // 金額（add-price-tracking）。nil = 無可計算金額 → 該行整行不渲染，不顯示 0。
        var upcomingExpiryCost: Double? = nil  // 前瞻：nearExpiry 桶中已記錄價格者的總和
        var wastedCost: Double? = nil          // 回顧：統計視窗內已丟棄且已記錄價格者的總和
        var expiredCost: Double? = nil         // 過期桶已記錄價格者的總和，供該桶卡片顯示

        // 卡片堆疊（restyle-home-as-card-stack）
        /// 目前完整顯示的那張卡。其餘卡片只露出頂緣。
        var selectedCard: HomeCard = .expired

        func items(in bucket: ExpiryStatus) -> [FoodItem] {
            switch bucket {
            case .expired: expired
            case .nearExpiry: nearExpiry
            case .fresh: fresh
            }
        }

        /// 該桶已記錄價格者的總和。nil = 無可計算金額（見 home-ui：不顯示 0）。
        func cost(in bucket: ExpiryStatus) -> Double? {
            switch bucket {
            case .expired: expiredCost
            case .nearExpiry: upcomingExpiryCost
            case .fresh: nil   // fresh 不列入前瞻金額（見 home-ui）
            }
        }

        /// 最急迫且非空的分桶對應的卡；全空時回過期卡。
        var mostUrgentNonEmptyCard: HomeCard {
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

// MARK: - HomeCard

/// 首頁那疊卡的身分。前兩張是摘要，後三張對應效期分桶。
///
/// 宣告順序即緊急度順序（見 home-ui：expired → nearExpiry → fresh），
/// 摘要卡排在最前。實際堆疊時完整顯示的那張會被移到最後，故此順序
/// 只決定「未選中者彼此的相對位置」。
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
