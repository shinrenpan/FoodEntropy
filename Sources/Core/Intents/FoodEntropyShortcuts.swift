import AppIntents

// 捷徑 app 與 Spotlight 的曝露點（見 app-intents、決策九）。
//
// phrases 必須含 `\(.applicationName)`，否則系統不接受。
// 字面值一律英文，由 build 抽取至 String Catalog 後補 zh-Hant——
// 繁中語句在繁中 Siri AI 開通前不會被辨識，但缺了會讓繁中使用者的
// 捷徑清單顯示為空，故仍須提供。
struct FoodEntropyShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddFoodItemIntent(),
            phrases: [
                "Add a food item to \(.applicationName)",
                "Record groceries in \(.applicationName)",
            ],
            shortTitle: "Add Food Item",
            systemImageName: "plus.circle"
        )

        AppShortcut(
            intent: MarkFoodConsumedIntent(),
            phrases: [
                // 帶參數槽的語句擺第一：Siri 能直接把聽到的名稱綁進 target，
                // 不必退回「Which one?」的消歧清單（2026-09-11 實機驗證）。
                "Mark \(\.$target) as used in \(.applicationName)",
                "Mark food as used in \(.applicationName)",
                "I used an item in \(.applicationName)",
            ],
            shortTitle: "Mark as Used",
            systemImageName: "checkmark.circle"
        )

        AppShortcut(
            intent: MarkFoodWastedIntent(),
            phrases: [
                "Mark \(\.$target) as discarded in \(.applicationName)",
                "Mark food as discarded in \(.applicationName)",
                "I threw away an item in \(.applicationName)",
            ],
            shortTitle: "Mark as Discarded",
            systemImageName: "trash"
        )

        AppShortcut(
            intent: ExtendFoodExpiryIntent(),
            phrases: [
                "Extend \(\.$target) in \(.applicationName)",
                "Extend a food item's expiry in \(.applicationName)",
            ],
            shortTitle: "Extend Expiry",
            systemImageName: "calendar.badge.plus"
        )

        AppShortcut(
            intent: FindFoodItemsIntent(),
            phrases: [
                "Find food items in \(.applicationName)",
                "What is expiring in \(.applicationName)",
            ],
            shortTitle: "Find Food Items",
            systemImageName: "magnifyingglass"
        )

        // .system.open 的自然語言辨識來自 schema 本身；這裡另外給它一張捷徑磚，
        // 讓 iOS 27 使用者也能在捷徑 app 裡直接取用（決策四）。
        if #available(iOS 27.0, *) {
            AppShortcut(
                intent: OpenFoodItemIntent(),
                phrases: [
                    "Open \(\.$target) in \(.applicationName)",
                    "Open a food item in \(.applicationName)",
                ],
                shortTitle: "Open Food Item",
                systemImageName: "arrow.up.forward.app"
            )
        }
    }
}
