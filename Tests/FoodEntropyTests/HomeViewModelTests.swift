import Foundation
import Testing
@testable import FoodEntropy

@MainActor
struct HomeViewModelTests {
    private func makeVM() throws -> (HomeViewModel, SwiftDataManager) {
        let manager = try SwiftDataManager(inMemory: true)
        let vm = HomeViewModel(manager: manager, notifications: NotificationService(active: false))
        return (vm, manager)
    }

    private let d0 = Date(timeIntervalSince1970: 1_700_000_000)

    @Test
    func `dataResponse foodsLoaded 更新 items`() async throws {
        let (vm, _) = try makeVM()
        let foods = FoodItem.mocks
        await vm.doAction(.dataResponse(.foodsLoaded(foods)))
        #expect(vm.state.items == foods)
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
