import AppIntents
import Foundation

// App Intents 背後的動作邏輯（見 app-intents）。
//
// Intent 型別只負責宣告參數與標題；實際寫入集中在此，理由有二：
// 1. 可注入 in-memory manager，測試不必碰真實 store。
// 2. `SwiftDataManager` 對不存在的 id 一律靜默 no-op——那對 app 內操作沒問題
//    （UI 不會給出不存在的 id），但 Intent 的 id 來自使用者選單或語音，
//    必須先確認目標存在，否則「刪掉的東西標記已使用」會回報成功。
@MainActor
struct FoodItemActions {
    private let manager: SwiftDataManager

    init(manager: SwiftDataManager) {
        self.manager = manager
    }

    // MARK: - 新增

    @discardableResult
    func add(
        name: String,
        purchaseDate: Date,
        expiryDate: Date,
        price: Double?
    ) throws -> FoodItem {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw FoodItemActionError.emptyName }
        // purchaseDate 與 expiryDate 同為 Date，呼叫端寫反不會有型別錯誤。
        // app 內的 DatePicker 以 `in: purchaseDate...` 擋住這件事，Intent 沒有那層
        // 保護，故在此比照——否則會靜默建出一筆「買進前就過期」的紀錄。
        guard expiryDate >= purchaseDate else { throw FoodItemActionError.expiryBeforePurchase }

        return manager.create(
            name: trimmed,
            purchaseDate: purchaseDate,
            expiryDate: expiryDate,
            imageData: nil,
            price: price
        )
    }

    // MARK: - 狀態轉換

    func markConsumed(id: UUID) throws {
        let item = try requireActive(id: id)
        manager.markConsumed(id: item.id)
    }

    func markWasted(id: UUID) throws {
        let item = try requireActive(id: id)
        manager.markWasted(id: item.id)
    }

    // MARK: - 延長效期

    /// 只改到期日。其餘欄位原樣回填——`SwiftDataManager.update` 刻意不給 price
    /// 預設值，漏傳即靜默清空既有價格（該處註釋已載明此陷阱）。
    func extendExpiry(id: UUID, to newExpiryDate: Date) throws {
        let item = try requireActive(id: id)
        guard newExpiryDate >= item.purchaseDate else {
            throw FoodItemActionError.expiryBeforePurchase
        }
        manager.update(
            id: item.id,
            name: item.name,
            purchaseDate: item.purchaseDate,
            expiryDate: newExpiryDate,
            imageData: item.imageData,
            price: item.price
        )
    }

    // MARK: - 讀取

    func activeItems() -> [FoodItem] {
        manager.fetchActiveFoods()
    }

    func search(_ query: String) -> [FoodItem] {
        FoodItemLookup.filter(manager.fetchActiveFoods(), matching: query)
    }

    // MARK: - Private

    /// 目標必須仍在 active 清單。已刪除或已 resolved 都視為找不到——
    /// 對已丟棄的食材再標記「已使用」不該悄悄成功。
    private func requireActive(id: UUID) throws -> FoodItem {
        guard let item = FoodItemLookup.find(manager.fetchActiveFoods(), id: id) else {
            throw FoodItemActionError.itemNotFound
        }
        return item
    }
}

// MARK: - 錯誤

// 採用 AppIntents 的本地化錯誤協定，訊息會直接顯示在捷徑 / Siri 上，
// 故字面值為英文並由 build 抽取至 String Catalog（見 localization）。
enum FoodItemActionError: Error, CustomLocalizedStringResourceConvertible {
    case itemNotFound
    case emptyName
    case expiryBeforePurchase

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .itemNotFound:
            "That food item is no longer in your list."
        case .emptyName:
            "The food item needs a name."
        case .expiryBeforePurchase:
            "The expiry date cannot be earlier than the purchase date."
        }
    }
}
