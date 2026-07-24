import Foundation
import Testing
@testable import FoodEntropy

@MainActor
struct HomeViewModelTests {
    private func makeVM(adsRemoved: Bool = false) throws -> (HomeViewModel, SwiftDataManager) {
        let manager = try SwiftDataManager(inMemory: true)
        let vm = HomeViewModel(
            manager: manager,
            store: StoreManager(adsRemoved: adsRemoved),
            notifications: NotificationService(active: false)
        )
        return (vm, manager)
    }

    private let d0 = Date(timeIntervalSince1970: 1_700_000_000)

    @Test
    func `onAppear 時持有移除廣告則 adsRemoved 為 true`() async throws {
        let (vm, _) = try makeVM(adsRemoved: true)
        await vm.doAction(.view(.onAppear))
        #expect(vm.state.adsRemoved == true)
    }

    @Test
    func `未購買移除廣告時 adsRemoved 為 false`() async throws {
        let (vm, _) = try makeVM(adsRemoved: false)
        await vm.doAction(.view(.onAppear))
        #expect(vm.state.adsRemoved == false)
    }

    // FoodItem.mocks 效期偏移：-2（expired）/ 0、+3（nearExpiry）/ +10（fresh）
    @Test
    func `dataResponse loaded 依效期分三桶`() async throws {
        let (vm, _) = try makeVM()
        await vm.doAction(.dataResponse(.loaded(active: FoodItem.mocks, resolved: [])))
        #expect(vm.state.expired.count == 1)
        #expect(vm.state.nearExpiry.count == 2)
        #expect(vm.state.fresh.count == 1)
    }

    @Test
    func `onAppear 從 manager 載入 active`() async throws {
        let (vm, manager) = try makeVM()
        manager.create(name: "牛奶", purchaseDate: d0, expiryDate: d0)
        await vm.doAction(.view(.onAppear))
        #expect(vm.state.items.count == 1)
        #expect(vm.state.items.first?.name == "牛奶")
    }

    @Test
    func `loaded 計算浪費統計`() async throws {
        let (vm, manager) = try makeVM()
        let a = manager.create(name: "A", purchaseDate: d0, expiryDate: d0)
        let b = manager.create(name: "B", purchaseDate: d0, expiryDate: d0)
        let c = manager.create(name: "C", purchaseDate: d0, expiryDate: d0)
        manager.markConsumed(id: a.id)
        manager.markConsumed(id: b.id)
        manager.markWasted(id: c.id)
        await vm.doAction(.dataResponse(.loaded(active: [], resolved: manager.fetchResolvedFoods())))
        #expect(vm.state.consumedCount == 2)
        #expect(vm.state.wastedCount == 1)
        #expect(vm.state.hasHistory == true)
    }

    @Test
    func `清除歷史統計刪除已處理並歸零`() async throws {
        let (vm, manager) = try makeVM()
        let a = manager.create(name: "吃了", purchaseDate: d0, expiryDate: d0)
        manager.markConsumed(id: a.id)
        await vm.doAction(.view(.onAppear))
        #expect(vm.state.hasHistory == true)

        await vm.doAction(.view(.clearHistoryDidTap))
        #expect(vm.state.showClearHistoryConfirm == true)
        await vm.doAction(.view(.clearHistoryConfirmed))
        #expect(vm.state.showClearHistoryConfirm == false)
        #expect(vm.state.hasHistory == false)
        #expect(vm.state.consumedCount == 0)
        #expect(manager.fetchResolvedFoods().isEmpty)
    }

    @Test
    func `deleteDidTap 設定 pendingDeleteItem 不刪除`() async throws {
        let (vm, manager) = try makeVM()
        let item = manager.create(name: "A", purchaseDate: d0, expiryDate: d0)
        await vm.doAction(.view(.onAppear))
        await vm.doAction(.view(.deleteDidTap(item)))
        #expect(vm.state.pendingDeleteItem == item)
        #expect(vm.state.items.count == 1)   // 尚未刪除
    }

    @Test
    func `deleteCancelled 清除 pendingDeleteItem`() async throws {
        let (vm, manager) = try makeVM()
        let item = manager.create(name: "A", purchaseDate: d0, expiryDate: d0)
        await vm.doAction(.view(.deleteDidTap(item)))
        await vm.doAction(.view(.deleteCancelled))
        #expect(vm.state.pendingDeleteItem == nil)
    }

    @Test
    func `deleteConfirmed 刪除並重載`() async throws {
        let (vm, manager) = try makeVM()
        let item = manager.create(name: "A", purchaseDate: d0, expiryDate: d0)
        await vm.doAction(.view(.onAppear))
        await vm.doAction(.view(.deleteDidTap(item)))
        await vm.doAction(.view(.deleteConfirmed))
        #expect(vm.state.pendingDeleteItem == nil)
        #expect(vm.state.items.isEmpty)
    }

    @Test
    func `consumeDidTap 移出清單`() async throws {
        let (vm, manager) = try makeVM()
        let item = manager.create(name: "A", purchaseDate: d0, expiryDate: d0)
        await vm.doAction(.view(.onAppear))
        await vm.doAction(.view(.consumeDidTap(item)))
        #expect(vm.state.items.isEmpty)
    }

    @Test
    func `wasteDidTap 移出清單`() async throws {
        let (vm, manager) = try makeVM()
        let item = manager.create(name: "A", purchaseDate: d0, expiryDate: d0)
        await vm.doAction(.view(.onAppear))
        await vm.doAction(.view(.wasteDidTap(item)))
        #expect(vm.state.items.isEmpty)
    }

    @Test
    func `extendDidTap 設定 extendingItem`() async throws {
        let (vm, manager) = try makeVM()
        let item = manager.create(name: "A", purchaseDate: d0, expiryDate: d0)
        await vm.doAction(.view(.extendDidTap(item)))
        #expect(vm.state.extendingItem == item)
    }

    @Test
    func `extendCommitted 更新到期日並清除 extendingItem`() async throws {
        let (vm, manager) = try makeVM()
        let item = manager.create(name: "A", purchaseDate: d0, expiryDate: d0)
        await vm.doAction(.view(.onAppear))
        await vm.doAction(.view(.extendDidTap(item)))
        let newExpiry = d0.addingTimeInterval(86_400 * 5)
        await vm.doAction(.view(.extendCommitted(newExpiry)))
        #expect(vm.state.extendingItem == nil)
        #expect(vm.state.items.first?.expiryDate == newExpiry)
    }
}
