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
        make(name: sample("已過期優格", "Expired Yogurt"), days: -2, price: 45),
        make(name: sample("雞蛋", "Eggs"), days: 0, price: 90),       // 到期當天，計入即將到期金額
        make(name: sample("豆腐", "Tofu"), days: 3, price: 35),       // nearExpiry 邊界，計入
        make(name: sample("高麗菜", "Cabbage"), days: 10),            // fresh，不計入
        make(name: sample("鮮奶", "Milk"), days: 1),                 // nearExpiry 但未記錄價格，不計入
    ]

    /// 依裝置語言選擇示範名稱。
    ///
    /// 食材名稱是「使用者資料」，依 `localization` 的規範不進 String Catalog——
    /// 但這些是 DEBUG 專用的示範資料，用於預覽與上架截圖。英文截圖若配上中文
    /// 食材名，看起來像沒做在地化，因此在此處直接依語言選字，不經 catalog。
    private static func sample(_ zh: String, _ en: String) -> String {
        Locale.current.language.languageCode?.identifier == "en" ? en : zh
    }

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
