import Foundation

// 效期分桶與前瞻金額。首頁與 Widget 都消費這一份——兩處顯示的數字必須相同，
// 各寫一份遲早會漂移（widget spec:「The widget shows the same status figures
// as the home screen」）。
//
// 只做計算，不碰儲存也不碰畫面：Widget 是獨立 process，能共用的只有純邏輯。
struct FoodStatusSummary: Sendable {
    let expired: [FoodItem]
    let nearExpiry: [FoodItem]
    let fresh: [FoodItem]

    /// 前瞻金額只取 nearExpiry——食材還救得回來時才說話。
    /// nil = 無可計算（該桶沒有任何項目帶價格），畫面據此整行不渲染，而非顯示 0。
    let upcomingExpiryCost: Double?

    var expiredCount: Int { expired.count }
    var nearExpiryCount: Int { nearExpiry.count }
    var freshCount: Int { fresh.count }

    /// - Parameters:
    ///   - active: 未解析的食材（active）。已使用／丟棄者不參與現況。
    ///   - today: 注入以利測試；效期是日期的函式，跨日就換桶。
    init(active: [FoodItem], today: Date = .now, calendar: Calendar = .current) {
        expired = active.filter { $0.expiryStatus(today: today, calendar: calendar) == .expired }
        nearExpiry = active.filter { $0.expiryStatus(today: today, calendar: calendar) == .nearExpiry }
        fresh = active.filter { $0.expiryStatus(today: today, calendar: calendar) == .fresh }
        upcomingExpiryCost = Self.sumPrices(nearExpiry)
    }

    /// 部分項目未填價格是常態（選填）。全無價格時回 nil，而非 0。
    static func sumPrices(_ items: [FoodItem]) -> Double? {
        let prices = items.compactMap(\.price)
        return prices.isEmpty ? nil : prices.reduce(0, +)
    }
}
