import Foundation
import SwiftData

// 持久化層（扮演 DTO 角色）。CloudKit-safe：
// - 所有屬性有預設值或為 optional（CloudKit 要求）
// - 無 @Attribute(.unique)（CloudKit 不支援）
// - imageData 用 externalStorage，隨 CloudKit 同步（02-architecture §2.1 §3）
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

    init(
        id: UUID = UUID(),
        name: String,
        purchaseDate: Date,
        expiryDate: Date,
        statusRaw: String = RecordStatus.active.rawValue,
        resolvedAt: Date? = nil,
        imageData: Data? = nil,
        createdAt: Date = Date.now
    ) {
        self.id = id
        self.name = name
        self.purchaseDate = purchaseDate
        self.expiryDate = expiryDate
        self.statusRaw = statusRaw
        self.resolvedAt = resolvedAt
        self.imageData = imageData
        self.createdAt = createdAt
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
            createdAt: createdAt
        )
    }
}
