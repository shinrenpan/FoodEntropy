import AppIntents
import Foundation

// 系統 schema 相關的動作（見 app-intents、決策四）。
//
// iOS 27 SDK 的 22 個 schema domain 沒有食材／庫存概念，但 `System` domain
// 不綁 domain，任何 app 都能採用——那是本專案取得 Siri 自然語言的唯一途徑。

// MARK: - 以自然語言開啟指定食材（.system.open，iOS 27+）

/// `OpenIntent` 由框架提供 `openAppWhenRun` 與預設 `perform()`，
/// 因此只需宣告 `target`。開啟後停在首頁（`navigation` 的既有目標）。
@available(iOS 27.0, *)
@AppIntent(schema: .system.open)
struct OpenFoodItemIntent {
    static let title: LocalizedStringResource = "Open Food Item"
    static let description = IntentDescription("Opens FoodEntropy showing a food item.")

    @Parameter(title: "Food Item")
    var target: FoodItemAppEntity
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
