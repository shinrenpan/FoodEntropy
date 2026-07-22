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
        createdAt: .now
    )

    // 涵蓋三種效期狀態，方便預覽顏色 / 分桶。
    static let mocks: [FoodItem] = [
        make(name: "已過期優格", days: -2),
        make(name: "雞蛋", days: 0),      // 到期當天
        make(name: "豆腐", days: 3),      // nearExpiry 邊界
        make(name: "高麗菜", days: 10),   // fresh
    ]

    private static func make(name: String, days: Int) -> FoodItem {
        FoodItem(
            id: UUID(),
            name: name,
            purchaseDate: .now,
            expiryDate: Calendar.current.date(byAdding: .day, value: days, to: .now)!,
            status: .active,
            resolvedAt: nil,
            imageData: nil,
            createdAt: .now
        )
    }
}
#endif
