import Foundation
import Testing
@testable import FoodEntropy

@MainActor
struct SwiftDataManagerTests {
    private func makeManager() throws -> SwiftDataManager {
        try SwiftDataManager(inMemory: true)
    }

    private let d0 = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("create 後 fetchActiveFoods 取得該筆")
    func createThenFetch() throws {
        let m = try makeManager()
        let created = m.create(name: "牛奶", purchaseDate: d0, expiryDate: d0)
        let items = m.fetchActiveFoods()
        #expect(items.count == 1)
        #expect(items.first?.id == created.id)
        #expect(items.first?.name == "牛奶")
        #expect(items.first?.status == .active)
    }

    @Test("fetchActiveFoods 依到期日升冪排序")
    func fetchSortedByExpiry() throws {
        let m = try makeManager()
        let later = d0.addingTimeInterval(86_400 * 5)
        let sooner = d0.addingTimeInterval(86_400 * 1)
        m.create(name: "晚", purchaseDate: d0, expiryDate: later)
        m.create(name: "早", purchaseDate: d0, expiryDate: sooner)
        let names = m.fetchActiveFoods().map(\.name)
        #expect(names == ["早", "晚"])
    }

    @Test("markConsumed / markWasted 後移出 active 清單並記錄 resolvedAt")
    func resolveRemovesFromActive() throws {
        let m = try makeManager()
        let a = m.create(name: "A", purchaseDate: d0, expiryDate: d0)
        let b = m.create(name: "B", purchaseDate: d0, expiryDate: d0)
        m.markConsumed(id: a.id)
        m.markWasted(id: b.id)
        #expect(m.fetchActiveFoods().isEmpty)
    }

    @Test("update 修改欄位")
    func updateMutatesFields() throws {
        let m = try makeManager()
        let item = m.create(name: "舊", purchaseDate: d0, expiryDate: d0)
        let newExpiry = d0.addingTimeInterval(86_400 * 3)
        m.update(id: item.id, name: "新", purchaseDate: d0, expiryDate: newExpiry, imageData: nil)
        let updated = m.fetchActiveFoods().first
        #expect(updated?.name == "新")
        #expect(updated?.expiryDate == newExpiry)
    }

    @Test("delete 為 hard delete，不留紀錄")
    func deleteRemoves() throws {
        let m = try makeManager()
        let item = m.create(name: "誤加", purchaseDate: d0, expiryDate: d0)
        m.delete(id: item.id)
        #expect(m.fetchActiveFoods().isEmpty)
    }
}
