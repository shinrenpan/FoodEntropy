import AppIntents
import CoreSpotlight
import Foundation

// App Intents 對外曝露的食材實體（見 app-intents）。
//
// 命名：persistence 已有名為 `FoodItemEntity` 的 SwiftData `@Model`，
// 兩者不可同名，故此處為 `FoodItemAppEntity`。
//
// 分層不變（決策二）：FoodItemEntity(@Model) → toDomain() → FoodItem → FoodItemAppEntity。
// 本型別只接觸 Domain Model，與 ViewModel / State 同樣不得持有 @Model。
struct FoodItemAppEntity: AppEntity, IndexedEntity {
    /// 沿用 `FoodItem.id`。螢幕感知標註與 Spotlight 索引都要求穩定且可持久化的識別碼，
    /// 重新產生的 id 會讓上一次啟動記下的指涉失效。
    let id: UUID
    let name: String
    let purchaseDate: Date
    let expiryDate: Date
    let price: Double?

    init(item: FoodItem) {
        self.id = item.id
        self.name = item.name
        self.purchaseDate = item.purchaseDate
        self.expiryDate = item.expiryDate
        self.price = item.price
    }

    /// 到期狀態讀取時才算，不隨 entity 持久化（見 food-item）。
    /// 刻意沿用 `ExpiryStatus.evaluate`，避免 Siri 唸出的狀態與畫面分歧。
    func expiryStatus(today: Date = .now, calendar: Calendar = .current) -> ExpiryStatus {
        ExpiryStatus.evaluate(expiryDate: expiryDate, today: today, calendar: calendar)
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Food Item")
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static var defaultQuery: FoodItemEntityQuery { FoodItemEntityQuery() }

    /// Spotlight 的語義索引內容。日期交給 FormatStyle，不手動拼字串。
    var attributeSet: CSSearchableItemAttributeSet {
        let set = CSSearchableItemAttributeSet(contentType: .item)
        set.title = name
        set.contentDescription = String(
            localized: "Expires \(expiryDate.formatted(date: .abbreviated, time: .omitted))"
        )
        return set
    }
}
