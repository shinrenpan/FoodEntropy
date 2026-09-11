import Foundation
import Testing
@testable import FoodEntropy

// Entity query 的判定邏輯（add-app-intents）。
// 純函式吃固定資料，測試不必建立真實 store。
struct FoodItemLookupTests {

    private let d0 = Date(timeIntervalSince1970: 1_700_000_000)

    private func item(_ name: String) -> FoodItem {
        FoodItem(
            id: UUID(),
            name: name,
            purchaseDate: d0,
            expiryDate: d0,
            status: .active,
            resolvedAt: nil,
            imageData: nil,
            createdAt: d0,
            price: nil
        )
    }

    // MARK: - 名稱篩選（對應 app-intents spec 的範例表格）

    @Test("名稱篩選不分大小寫且允許部分比對", arguments: [
        (["Milk", "Milk Chocolate", "Bread"], "milk", ["Milk", "Milk Chocolate"]),
        (["Milk", "Bread"], "MILK", ["Milk"]),
        (["Milk", "Bread"], "cheese", []),
    ])
    func filterByName(stored: [String], query: String, expected: [String]) {
        let items = stored.map(item)
        let matched = FoodItemLookup.filter(items, matching: query)
        #expect(matched.map(\.name) == expected)
    }

    // MARK: - 依 id 查找

    @Test("已刪除的 id 查不到任何 entity")
    func deletedIdYieldsNothing() {
        let items = [item("Milk"), item("Bread")]
        let deleted = UUID()
        #expect(FoodItemLookup.find(items, ids: [deleted]).isEmpty)
        #expect(FoodItemLookup.find(items, id: deleted) == nil)
    }

    @Test("存在的 id 取回對應食材")
    func existingIdIsFound() {
        let items = [item("Milk"), item("Bread")]
        let target = items[1]
        #expect(FoodItemLookup.find(items, id: target.id)?.name == "Bread")
        #expect(FoodItemLookup.find(items, ids: [target.id]).count == 1)
    }
}
