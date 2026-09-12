import AppIntents
import Foundation
import SwiftUI

// 四個核心動作（見 app-intents）。
//
// 全部 `openAppWhenRun = false`——不開 app 才是 App Intents 的價值所在；
// 唯一例外是 `OpenFoodItemIntent`，由框架的 `OpenIntent` 預設提供該行為。
//
// 這些型別不帶 `@available` 包覆：schema 無關，iOS 26 上一樣可用（決策四）。
// 寫入一律經 `FoodItemActions`，它負責「目標必須仍在 active」的把關。

// MARK: - 新增

struct AddFoodItemIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Food Item"
    static let description = IntentDescription("Records a new food item with its expiry date.")
    static let openAppWhenRun = false

    @Parameter(title: "Name")
    var name: String

    @Parameter(title: "Expiry Date")
    var expiryDate: Date

    /// 選填：多數情況就是今天，逼使用者每次都填會讓捷徑變得難用。
    @Parameter(title: "Purchase Date")
    var purchaseDate: Date?

    @Parameter(title: "Price")
    var price: Double?

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$name) expiring on \(\.$expiryDate)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<FoodItemAppEntity> & ProvidesDialog & ShowsSnippetView {
        let item = try FoodItemActions(manager: .shared).add(
            name: name,
            purchaseDate: purchaseDate ?? .now,
            expiryDate: expiryDate,
            price: price
        )
        // 不開 app 的動作若不回話也不顯示任何東西，使用者無從確認成功（見決策十一）。
        return .result(
            value: FoodItemAppEntity(item: item),
            dialog: FoodItemActionOutcome.added.dialog(name: item.name),
            view: IntentSnippetView(outcome: .added, name: item.name, expiryDate: item.expiryDate)
        )
    }
}

// MARK: - 標記已使用

struct MarkFoodConsumedIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Food as Used"
    static let description = IntentDescription("Marks a food item as used so it leaves your list.")
    static let openAppWhenRun = false

    @Parameter(title: "Food Item")
    var target: FoodItemAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Mark \(\.$target) as used")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        try FoodItemActions(manager: .shared).markConsumed(id: target.id)
        return .result(
            dialog: FoodItemActionOutcome.consumed.dialog(name: target.name),
            view: IntentSnippetView(outcome: .consumed, name: target.name, expiryDate: target.expiryDate)
        )
    }
}

// MARK: - 標記丟棄

struct MarkFoodWastedIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Food as Discarded"
    static let description = IntentDescription("Marks a food item as discarded so it leaves your list.")
    static let openAppWhenRun = false

    @Parameter(title: "Food Item")
    var target: FoodItemAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Mark \(\.$target) as discarded")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        try FoodItemActions(manager: .shared).markWasted(id: target.id)
        return .result(
            dialog: FoodItemActionOutcome.wasted.dialog(name: target.name),
            view: IntentSnippetView(outcome: .wasted, name: target.name, expiryDate: target.expiryDate)
        )
    }
}

// MARK: - 延長效期

struct ExtendFoodExpiryIntent: AppIntent {
    static let title: LocalizedStringResource = "Extend Food Expiry"
    static let description = IntentDescription("Moves a food item's expiry date without changing anything else.")
    static let openAppWhenRun = false

    @Parameter(title: "Food Item")
    var target: FoodItemAppEntity

    @Parameter(title: "New Expiry Date")
    var newExpiryDate: Date

    static var parameterSummary: some ParameterSummary {
        Summary("Extend \(\.$target) to \(\.$newExpiryDate)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        try FoodItemActions(manager: .shared).extendExpiry(id: target.id, to: newExpiryDate)
        // 顯示的是**新的**到期日——使用者要確認的正是改對了沒有。
        return .result(
            dialog: FoodItemActionOutcome.extended.dialog(name: target.name),
            view: IntentSnippetView(outcome: .extended, name: target.name, expiryDate: newExpiryDate)
        )
    }
}
