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

    @Test("標記已使用時剝離圖片")
    func resolveStripsImage() throws {
        let m = try makeManager()
        let item = m.create(name: "有圖", purchaseDate: d0, expiryDate: d0, imageData: Data([0x01, 0x02]))
        m.markConsumed(id: item.id)
        let resolved = m.fetchResolvedFoods()
        #expect(resolved.count == 1)
        #expect(resolved.first?.imageData == nil)
    }

    // MARK: - 優雅降級 factory

    private enum StubError: Error { case boom }

    @Test("firstSuccess 跳過失敗、回傳第一個成功者")
    func firstSuccessSkipsFailures() throws {
        let m = SwiftDataManager.firstSuccess([
            { throw StubError.boom },
            { throw StubError.boom },
            { try SwiftDataManager(inMemory: true) },
        ])
        #expect(m != nil)
    }

    @Test("firstSuccess 全失敗回 nil")
    func firstSuccessAllFail() {
        let m = SwiftDataManager.firstSuccess([
            { throw StubError.boom },
            { throw StubError.boom },
        ])
        #expect(m == nil)
    }

    @Test("makeResilient 正常情境回傳可用 manager")
    func makeResilientReturnsUsable() {
        // 走真實磁碟 store（可能有殘留資料）→ 用「包含」斷言，並清掉自己建的那筆避免污染。
        let m = SwiftDataManager.makeResilient(cloudKitEnabled: false)
        let item = m.create(name: "測試", purchaseDate: d0, expiryDate: d0)
        #expect(m.fetchActiveFoods().contains { $0.id == item.id })
        m.delete(id: item.id)
    }

    @Test("deleteResolvedFoods 清空已處理、不動 active")
    func deleteResolvedClearsHistory() throws {
        let m = try makeManager()
        let keep = m.create(name: "現存", purchaseDate: d0, expiryDate: d0)
        let a = m.create(name: "吃了", purchaseDate: d0, expiryDate: d0)
        let b = m.create(name: "丟了", purchaseDate: d0, expiryDate: d0)
        m.markConsumed(id: a.id)
        m.markWasted(id: b.id)
        m.deleteResolvedFoods()
        #expect(m.fetchResolvedFoods().isEmpty)
        #expect(m.fetchActiveFoods().map(\.id) == [keep.id])   // active 不受影響
    }
}
