#if DEBUG
import Foundation

// Mock 掛在 Domain Model 上，供 Preview 與測試使用（mvvmc-model）。整檔 #if DEBUG。
extension FoodItem {
    static let mock = FoodItem(
        id: UUID(),
        name: "牛奶",
        purchaseDate: .now,
        expiryDate: Calendar.current.date(byAdding: .day, value: 2, to: .now)!,
        status: .active,
        resolvedAt: nil,
        imageData: nil,
        createdAt: .now,
        price: 60
    )

    // 涵蓋三種效期狀態，方便預覽顏色 / 分桶。
    // 價格刻意只填部分——反映真實情況（選填），也讓「至少」語氣的金額有意義。
    static let mocks: [FoodItem] = [
        make(name: "已過期優格", days: -2, price: 45),
        make(name: "雞蛋", days: 0, price: 90),       // 到期當天，計入即將到期金額
        make(name: "豆腐", days: 3, price: 35),       // nearExpiry 邊界，計入
        make(name: "高麗菜", days: 10),               // fresh，不計入
        make(name: "鮮奶", days: 1),                  // nearExpiry 但未記錄價格，不計入
    ]

    private static func make(name: String, days: Int, price: Double? = nil) -> FoodItem {
        FoodItem(
            id: UUID(),
            name: name,
            purchaseDate: .now,
            expiryDate: Calendar.current.date(byAdding: .day, value: days, to: .now)!,
            status: .active,
            resolvedAt: nil,
            imageData: nil,
            createdAt: .now,
            price: price
        )
    }
}
#endif
