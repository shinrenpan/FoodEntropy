import Foundation
import Testing
@testable import FoodEntropy

@MainActor
struct AnalyticsViewModelTests {
    private func makeVM() throws -> (AnalyticsViewModel, SwiftDataManager) {
        let manager = try SwiftDataManager(inMemory: true)
        return (AnalyticsViewModel(manager: manager), manager)
    }

    private let d0 = Date(timeIntervalSince1970: 1_700_000_000)

    // FoodItem.mocks 效期偏移：-2（expired）/ 0、+3（nearExpiry）/ +10（fresh）
    @Test
    func `loaded 依效期分三桶`() async throws {
        let (vm, _) = try makeVM()
        await vm.doAction(.dataResponse(.loaded(active: FoodItem.mocks, resolved: [])))
        #expect(vm.state.expired.count == 1)
        #expect(vm.state.nearExpiry.count == 2)
        #expect(vm.state.fresh.count == 1)
    }

    @Test
    func `loaded 計算吃掉與丟棄數量`() async throws {
        let (vm, manager) = try makeVM()
        // 建立並標記：2 吃掉、1 丟棄
        let a = manager.create(name: "A", purchaseDate: d0, expiryDate: d0)
        let b = manager.create(name: "B", purchaseDate: d0, expiryDate: d0)
        let c = manager.create(name: "C", purchaseDate: d0, expiryDate: d0)
        manager.markConsumed(id: a.id)
        manager.markConsumed(id: b.id)
        manager.markWasted(id: c.id)
        let resolved = manager.fetchResolvedFoods()
        await vm.doAction(.dataResponse(.loaded(active: [], resolved: resolved)))
        #expect(vm.state.consumedCount == 2)
        #expect(vm.state.wastedCount == 1)
    }

    @Test
    func `浪費率計算正確`() async throws {
        let (vm, _) = try makeVM()
        var consumed: [FoodItem] = []
        var wasted: [FoodItem] = []
        for _ in 0..<3 { consumed.append(makeResolved(.consumed)) }
        wasted.append(makeResolved(.wasted))
        await vm.doAction(.dataResponse(.loaded(active: [], resolved: consumed + wasted)))
        // 丟棄 1 /（吃掉 3 + 丟棄 1）= 0.25
        #expect(vm.state.wasteRate == 0.25)
    }

    @Test
    func `無已處理紀錄時浪費率為 nil`() async throws {
        let (vm, _) = try makeVM()
        await vm.doAction(.dataResponse(.loaded(active: [], resolved: [])))
        #expect(vm.state.wasteRate == nil)
    }

    @Test
    func `onAppear 從 manager 載入現況與統計`() async throws {
        let (vm, manager) = try makeVM()
        let now = Date.now
        let cal = Calendar.current
        manager.create(name: "還早", purchaseDate: now, expiryDate: cal.date(byAdding: .day, value: 10, to: now)!)
        let eaten = manager.create(name: "吃了", purchaseDate: now, expiryDate: now)
        manager.markConsumed(id: eaten.id)
        await vm.doAction(.view(.onAppear))
        #expect(vm.state.fresh.count == 1)
        #expect(vm.state.consumedCount == 1)
    }

    // MARK: - helper

    private func makeResolved(_ status: RecordStatus) -> FoodItem {
        FoodItem(id: UUID(), name: "x", purchaseDate: d0, expiryDate: d0,
                 status: status, resolvedAt: d0, imageData: nil, createdAt: d0)
    }
}
