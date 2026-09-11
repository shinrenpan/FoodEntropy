import AppIntents
import Foundation

// 系統向 app 索取食材實體的入口（見 app-intents）。
//
// 資料一律取自 `SwiftDataManager.shared`——App Intents 可能在沒有 scene 時執行，
// 自行建立 container 會與畫面的 context 分岔（決策一）。
//
// 篩選與查找的判定放在 `FoodItemLookup` 的純函式，讓測試不必碰真實 store。
struct FoodItemEntityQuery: EntityStringQuery {

    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [FoodItemAppEntity] {
        let active = SwiftDataManager.shared.fetchActiveFoodsWithoutImages()
        return FoodItemLookup.find(active, ids: identifiers).map(FoodItemAppEntity.init(item:))
    }

    /// 使用者在捷徑的參數欄位打字、或 Siri 聽到名稱時走這條。
    @MainActor
    func entities(matching string: String) async throws -> [FoodItemAppEntity] {
        let active = SwiftDataManager.shared.fetchActiveFoodsWithoutImages()
        return FoodItemLookup.filter(active, matching: string).map(FoodItemAppEntity.init(item:))
    }

    /// 無條件時提供現存食材，讓使用者在捷徑的參數選單直接挑選。
    /// 只給 active——已使用／丟棄的食材不該出現在「要對哪一筆動作」的清單裡。
    @MainActor
    func suggestedEntities() async throws -> [FoodItemAppEntity] {
        SwiftDataManager.shared.fetchActiveFoodsWithoutImages().map(FoodItemAppEntity.init(item:))
    }
}
