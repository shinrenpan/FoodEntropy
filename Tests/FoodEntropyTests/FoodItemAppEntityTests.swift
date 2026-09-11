import Foundation
import Testing
@testable import FoodEntropy

// App Intents 的 entity 轉換（add-app-intents 決策二）。
// 分層：FoodItemEntity(@Model) → toDomain() → FoodItem → FoodItemAppEntity。
// 本層只接觸 Domain Model，不得持有 @Model。
struct FoodItemAppEntityTests {

    private let d0 = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeItem(
        name: String = "Milk",
        expiryOffsetDays: Int = 10,
        price: Double? = 89.0
    ) -> FoodItem {
        FoodItem(
            id: UUID(),
            name: name,
            purchaseDate: d0,
            expiryDate: d0.addingTimeInterval(Double(expiryOffsetDays) * 86_400),
            status: .active,
            resolvedAt: nil,
            imageData: nil,
            createdAt: d0,
            price: price
        )
    }

    @Test("entity 的 id 取自 FoodItem.id，同一筆轉兩次結果相同")
    func identifierIsStable() {
        let item = makeItem()
        let first = FoodItemAppEntity(item: item)
        let second = FoodItemAppEntity(item: item)
        #expect(first.id == item.id)
        #expect(first.id == second.id)
    }

    @Test("entity 攜帶名稱、購買日、到期日與價格")
    func carriesDomainValues() {
        let item = makeItem()
        let entity = FoodItemAppEntity(item: item)
        #expect(entity.name == item.name)
        #expect(entity.purchaseDate == item.purchaseDate)
        #expect(entity.expiryDate == item.expiryDate)
        #expect(entity.price == item.price)
    }

    @Test("沒有價格的食材轉出的 entity 價格為 nil，不補零")
    func missingPriceStaysNil() {
        let entity = FoodItemAppEntity(item: makeItem(price: nil))
        #expect(entity.price == nil)
    }

    /// ExpiryStatus 是讀取時算出的，不持久化（見 food-item）。
    /// entity 必須沿用同一個判定，否則 Siri 唸出的狀態會與畫面不一致。
    @Test("到期狀態於讀取時計算，與 ExpiryStatus.evaluate 一致")
    func expiryStatusIsComputedOnRead() {
        let today = d0
        let expired = makeItem(expiryOffsetDays: -1)
        let near = makeItem(expiryOffsetDays: 2)
        let fresh = makeItem(expiryOffsetDays: 30)

        #expect(FoodItemAppEntity(item: expired).expiryStatus(today: today) == .expired)
        #expect(FoodItemAppEntity(item: near).expiryStatus(today: today) == .nearExpiry)
        #expect(FoodItemAppEntity(item: fresh).expiryStatus(today: today) == .fresh)
    }

    // MARK: - Spotlight 索引屬性（app-intents: Food items are indexed for Spotlight）

    @Test("Spotlight 屬性以食材名稱為標題")
    func attributeSetUsesNameAsTitle() {
        let entity = FoodItemAppEntity(item: makeItem(name: "Milk"))
        #expect(entity.attributeSet.title == "Milk")
    }

    @Test("Spotlight 屬性的描述帶有到期日")
    func attributeSetDescribesExpiry() {
        let item = makeItem()
        let entity = FoodItemAppEntity(item: item)
        // contentDescription 是 ObjC 橋接來的 String!，直接取用需自行給退路。
        let description = entity.attributeSet.contentDescription ?? ""
        let year = Calendar.current.component(.year, from: item.expiryDate)
        #expect(description.contains(String(year)))
    }
}
