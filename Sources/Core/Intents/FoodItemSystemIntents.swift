import AppIntents
import Foundation

// 系統 schema 相關的動作（見 app-intents、決策四）。
//
// iOS 27 SDK 的 22 個 schema domain 沒有食材／庫存概念，但 `System` domain
// 不綁 domain，任何 app 都能採用——那是本專案取得 Siri 自然語言的唯一途徑。

// MARK: - 開啟指定食材

/// Spotlight 點擊食材結果、以及 Siri 的「開啟某食材」都走這個 Intent。
///
/// **刻意不採用 `.system.open` schema**：該 schema 為 iOS 27+，掛上去會讓整個
/// 型別被 `@available(iOS 27.0, *)` 鎖住，而 `OpenIntent` 協定本身 iOS 16 就有。
/// schema 換來的是 Siri 的自由語句理解——那需要 Siri AI（英文限定、繁中未公布
/// 日期），而 `AppShortcut` 的 `"Open \(\.$target) in \(.applicationName)"` 語句
/// 不綁 schema 也能讓 Siri 叫用。代價與收益不成比例：拿掉 schema，
/// Spotlight 點擊進 detail 在 iOS 26 與 27 都能用（見 app-intents 決策十）。
struct OpenFoodItemIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Food Item"
    static let description = IntentDescription("Opens FoodEntropy showing a food item.")

    @Parameter(title: "Food Item")
    var target: FoodItemAppEntity

    /// 放入待處理的 `Deeplink`，由 `SceneDelegate` 在 scene 連上或回到前景時取用。
    ///
    /// 刻意**不用** `UIApplication.shared.open(url)`：Siri 觸發時 app 不在前景，
    /// 非前景 app 呼叫 open 會被系統擋掉（2026-09-12 實機確認：Spotlight 可、
    /// Siri 不可）。`openAppWhenRun` 會把 app 帶到前景，所以一定有取用時機。
    @MainActor
    func perform() async throws -> some IntentResult {
        PendingDeeplink.set(.foodItem(target.id))
        return .result()
    }
}

// MARK: - 搜尋食材（回傳值，不需 app 內搜尋介面）

/// 刻意**不**採用 `.system.searchInApp`：該 schema 對應
/// `ShowInAppSearchResultsIntent`，其契約是「開啟 app 並顯示搜尋結果」，
/// 而首頁目前沒有搜尋介面。在補上該介面之前，採用它會開啟 app 卻顯示未經篩選的
/// 完整清單——比不提供更糟。
///
/// 此版本以回傳 entity 陣列的形式提供搜尋，捷徑與 Spotlight 立即可用，
/// 且不綁 iOS 27。待首頁搜尋介面確定後再評估改用 schema。
struct FindFoodItemsIntent: AppIntent {
    static let title: LocalizedStringResource = "Find Food Items"
    static let description = IntentDescription("Finds food items in your list by name.")
    static let openAppWhenRun = false

    @Parameter(title: "Name Contains")
    var query: String

    static var parameterSummary: some ParameterSummary {
        Summary("Find food items matching \(\.$query)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[FoodItemAppEntity]> {
        let matched = FoodItemActions(manager: .shared).search(query)
        return .result(value: matched.map(FoodItemAppEntity.init(item:)))
    }
}
