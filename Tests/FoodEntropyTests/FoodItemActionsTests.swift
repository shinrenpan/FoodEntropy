import Foundation
import Testing
@testable import FoodEntropy

// App Intents 背後的動作邏輯（add-app-intents 決策三）。
// 以 in-memory manager 注入，測試不碰真實 store。
@MainActor
struct FoodItemActionsTests {

    private func makeActions() throws -> (FoodItemActions, SwiftDataManager) {
        let manager = try SwiftDataManager(inMemory: true)
        return (FoodItemActions(manager: manager), manager)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }

    // MARK: - 新增

    @Test("新增的食材與 app 內建立的一致：status 為 active、resolvedAt 未設")
    func addCreatesActiveItem() throws {
        let (actions, manager) = try makeActions()
        let created = try actions.add(
            name: "Milk",
            purchaseDate: date(2026, 9, 11),
            expiryDate: date(2026, 9, 20),
            price: 89.0
        )
        let stored = manager.fetchActiveFoods()
        #expect(stored.count == 1)
        #expect(stored.first?.id == created.id)
        #expect(stored.first?.status == .active)
        #expect(stored.first?.resolvedAt == nil)
        #expect(stored.first?.price == 89.0)
    }

    // MARK: - 標記

    @Test("標記已使用後離開 active 清單")
    func markConsumedRemovesFromActive() throws {
        let (actions, manager) = try makeActions()
        let item = manager.create(name: "Bread", purchaseDate: date(2026, 9, 1), expiryDate: date(2026, 9, 5))
        try actions.markConsumed(id: item.id)
        #expect(manager.fetchActiveFoods().isEmpty)
        #expect(manager.fetchResolvedFoods().first?.status == .consumed)
    }

    @Test("標記丟棄後離開 active 清單")
    func markWastedRemovesFromActive() throws {
        let (actions, manager) = try makeActions()
        let item = manager.create(name: "Spinach", purchaseDate: date(2026, 9, 1), expiryDate: date(2026, 9, 5))
        try actions.markWasted(id: item.id)
        #expect(manager.fetchActiveFoods().isEmpty)
        #expect(manager.fetchResolvedFoods().first?.status == .wasted)
    }

    // MARK: - 延長效期（對應 app-intents spec 的 Milk / 89.0 範例）

    /// `SwiftDataManager.update` 刻意不給 price 預設值，忘記傳就會靜默清空。
    /// 延長效期只該動到期日，其餘欄位必須原封不動。
    @Test("延長效期不動到名稱、購買日、照片與價格")
    func extendPreservesOtherValues() throws {
        let (actions, manager) = try makeActions()
        let photo = Data([0xFF, 0xD8, 0xFF])
        let item = manager.create(
            name: "Milk",
            purchaseDate: date(2026, 9, 11),
            expiryDate: date(2026, 9, 20),
            imageData: photo,
            price: 89.0
        )

        try actions.extendExpiry(id: item.id, to: date(2026, 9, 27))

        let stored = try #require(manager.fetchActiveFoods().first)
        #expect(stored.expiryDate == date(2026, 9, 27))
        #expect(stored.price == 89.0)
        #expect(stored.imageData == photo)
        #expect(stored.name == "Milk")
        #expect(stored.purchaseDate == date(2026, 9, 11))
    }

    // MARK: - 目標不存在時回報錯誤（app-intents: Actions fail loudly when the target no longer exists）

    /// `SwiftDataManager` 的 markConsumed / markWasted / update 對不存在的 id 一律靜默 no-op。
    /// 那在 app 內沒問題（UI 不會給出不存在的 id），但 Intent 的 id 來自使用者選單或語音，
    /// 靜默成功會讓使用者以為動作生效了。
    @Test("對已刪除的食材動作會丟錯且不寫入")
    func actingOnDeletedItemThrows() throws {
        let (actions, manager) = try makeActions()
        let item = manager.create(name: "Milk", purchaseDate: date(2026, 9, 11), expiryDate: date(2026, 9, 20))
        manager.delete(id: item.id)

        #expect(throws: FoodItemActionError.itemNotFound) { try actions.markConsumed(id: item.id) }
        #expect(throws: FoodItemActionError.itemNotFound) { try actions.markWasted(id: item.id) }
        #expect(throws: FoodItemActionError.itemNotFound) {
            try actions.extendExpiry(id: item.id, to: date(2026, 9, 27))
        }
        #expect(manager.fetchActiveFoods().isEmpty)
        #expect(manager.fetchResolvedFoods().isEmpty)
    }

    @Test("對已標記丟棄的食材再標記已使用會丟錯，原狀態不變")
    func actingOnResolvedItemThrows() throws {
        let (actions, manager) = try makeActions()
        let item = manager.create(name: "Spinach", purchaseDate: date(2026, 9, 1), expiryDate: date(2026, 9, 5))
        try actions.markWasted(id: item.id)

        #expect(throws: FoodItemActionError.itemNotFound) { try actions.markConsumed(id: item.id) }
        #expect(manager.fetchResolvedFoods().first?.status == .wasted)
    }

    // MARK: - 參數誤用（audit：兩個相鄰的 Date 參數可互換誤傳）

    @Test("到期日早於購買日會丟錯，不建立紀錄")
    func expiryBeforePurchaseThrows() throws {
        let (actions, manager) = try makeActions()
        #expect(throws: FoodItemActionError.expiryBeforePurchase) {
            try actions.add(
                name: "Milk",
                purchaseDate: date(2026, 9, 20),
                expiryDate: date(2026, 9, 11),
                price: nil
            )
        }
        #expect(manager.fetchActiveFoods().isEmpty)
    }

    @Test("空白名稱會丟錯，不建立紀錄")
    func emptyNameThrows() throws {
        let (actions, manager) = try makeActions()
        #expect(throws: FoodItemActionError.emptyName) {
            try actions.add(name: "   ", purchaseDate: date(2026, 9, 11), expiryDate: date(2026, 9, 20), price: nil)
        }
        #expect(manager.fetchActiveFoods().isEmpty)
    }
}
