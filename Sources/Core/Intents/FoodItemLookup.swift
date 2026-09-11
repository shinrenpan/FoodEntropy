import Foundation

// 食材查找與篩選的判定（見 app-intents）。
//
// 刻意做成吃 `[FoodItem]` 的純函式，而非直接查 store：
// 判定邏輯得以在測試中以固定資料驗證，不必建立真實連線，
// 與 `SwiftDataManager.firstSuccess` 的既有作法一致。
enum FoodItemLookup {

    /// 依 id 取出對應食材。找不到的 id 直接略過——呼叫端（Intent）負責把
    /// 「要求了 N 筆卻只拿到 M 筆」轉成可見錯誤，而非在此靜默補位。
    static func find(_ items: [FoodItem], ids: [UUID]) -> [FoodItem] {
        let wanted = Set(ids)
        return items.filter { wanted.contains($0.id) }
    }

    static func find(_ items: [FoodItem], id: UUID) -> FoodItem? {
        items.first { $0.id == id }
    }

    /// 依名稱做不分大小寫的部分比對，保留原本的排序（`fetchActiveFoods` 已依到期日升冪）。
    /// 用 `localizedStandardContains` 而非 `lowercased().contains`：前者同時處理大小寫、
    /// 變音符號與寬度差異，中文與英文食材名都適用。
    static func filter(_ items: [FoodItem], matching query: String) -> [FoodItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return items }
        return items.filter { $0.name.localizedStandardContains(trimmed) }
    }
}
