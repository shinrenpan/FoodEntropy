import Foundation
import SwiftData

// 持久化層（扮演 DTO 角色）。CloudKit-safe：
// - 所有屬性有預設值或為 optional（CloudKit 要求）
// - 無 @Attribute(.unique)（CloudKit 不支援）
// - imageData 用 externalStorage，隨 CloudKit 同步（見 persistence）
@Model
final class FoodItemEntity {
    var id: UUID = UUID()
    var name: String = ""
    var purchaseDate: Date = Date.now
    var expiryDate: Date = Date.now
    var statusRaw: String = RecordStatus.active.rawValue   // active / consumed / wasted
    var resolvedAt: Date?
    @Attribute(.externalStorage) var imageData: Data?
    var createdAt: Date = Date.now
    // 選填。這筆記錄的總花費（非單價，無數量欄位）。optional 即符合 CloudKit-safe。
    // ⚠️ 與 imageData 不同：解析（consumed / wasted）時**不清除**，回顧金額需要它。
    var price: Double?

    init(
        id: UUID = UUID(),
        name: String,
        purchaseDate: Date,
        expiryDate: Date,
        statusRaw: String = RecordStatus.active.rawValue,
        resolvedAt: Date? = nil,
        imageData: Data? = nil,
        createdAt: Date = Date.now,
        price: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.purchaseDate = purchaseDate
        self.expiryDate = expiryDate
        self.statusRaw = statusRaw
        self.resolvedAt = resolvedAt
        self.imageData = imageData
        self.createdAt = createdAt
        self.price = price
    }
}

// MARK: - toDomain（邊界轉換是 DTO 自身的責任）

extension FoodItemEntity {
    func toDomain() -> FoodItem {
        FoodItem(
            id: id,
            name: name,
            purchaseDate: purchaseDate,
            expiryDate: expiryDate,
            status: RecordStatus(rawValue: statusRaw) ?? .active,
            resolvedAt: resolvedAt,
            imageData: imageData,
            createdAt: createdAt,
            price: price
        )
    }
}
