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

    // FoodItem.mocks 效期偏移：-2（expired）/ 0、+1、+3（nearExpiry）/ +10（fresh）
    @Test
    func `dataResponse loaded 依效期分三桶`() async throws {
        let (vm, _) = try makeVM()
        await vm.doAction(.dataResponse(.loaded(active: FoodItem.mocks, resolved: [])))
        #expect(vm.state.expired.count == 1)
        #expect(vm.state.nearExpiry.count == 3)
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

    // MARK: - 金額（add-price-tracking）

    /// mocks 價格分佈：已過期優格 -2 天 45、雞蛋 0 天 90、豆腐 +3 天 35、
    /// 高麗菜 +10 天無價、鮮奶 +1 天無價。nearExpiry 且有價 = 90 + 35 = 125。
    @Test
    func `前瞻金額只計 nearExpiry 且已記錄價格者`() async throws {
        let (vm, _) = try makeVM()
        await vm.doAction(.dataResponse(.loaded(active: FoodItem.mocks, resolved: [])))
        #expect(vm.state.upcomingExpiryCost == 125)
    }

    @Test
    func `前瞻金額不計入已過期與保存期限內`() async throws {
        let (vm, _) = try makeVM()
        let expired = FoodItem(
            id: UUID(), name: "過期", purchaseDate: d0,
            expiryDate: Calendar.current.date(byAdding: .day, value: -1, to: .now)!,
            status: .active, resolvedAt: nil, imageData: nil, createdAt: d0, price: 500
        )
        let fresh = FoodItem(
            id: UUID(), name: "新鮮", purchaseDate: d0,
            expiryDate: Calendar.current.date(byAdding: .day, value: 10, to: .now)!,
            status: .active, resolvedAt: nil, imageData: nil, createdAt: d0, price: 800
        )
        await vm.doAction(.dataResponse(.loaded(active: [expired, fresh], resolved: [])))
        #expect(vm.state.upcomingExpiryCost == nil)   // 兩者皆不計入 → 無可計算金額
    }

    @Test
    func `無任何 nearExpiry 帶價格時前瞻金額為 nil`() async throws {
        let (vm, _) = try makeVM()
        let unpriced = FoodItem(
            id: UUID(), name: "無價", purchaseDate: d0,
            expiryDate: Calendar.current.date(byAdding: .day, value: 1, to: .now)!,
            status: .active, resolvedAt: nil, imageData: nil, createdAt: d0, price: nil
        )
        await vm.doAction(.dataResponse(.loaded(active: [unpriced], resolved: [])))
        #expect(vm.state.upcomingExpiryCost == nil)
    }

    @Test
    func `已丟棄金額只計視窗內且已記錄價格的丟棄項`() async throws {
        let (vm, _) = try makeVM()
        let recentWasted = FoodItem(
            id: UUID(), name: "近期丟棄", purchaseDate: d0, expiryDate: d0,
            status: .wasted, resolvedAt: .now, imageData: nil, createdAt: d0, price: 200
        )
        let oldWasted = FoodItem(
            id: UUID(), name: "視窗外丟棄", purchaseDate: d0, expiryDate: d0,
            status: .wasted,
            resolvedAt: Calendar.current.date(byAdding: .day, value: -60, to: .now)!,
            imageData: nil, createdAt: d0, price: 999
        )
        let consumed = FoodItem(
            id: UUID(), name: "吃掉的", purchaseDate: d0, expiryDate: d0,
            status: .consumed, resolvedAt: .now, imageData: nil, createdAt: d0, price: 300
        )
        await vm.doAction(.dataResponse(.loaded(
            active: [], resolved: [recentWasted, oldWasted, consumed]
        )))
        #expect(vm.state.wastedCost == 200)   // 只算視窗內、只算 wasted
    }

    @Test
    func `無已記錄價格的丟棄項時金額為 nil`() async throws {
        let (vm, _) = try makeVM()
        let wastedNoPrice = FoodItem(
            id: UUID(), name: "無價丟棄", purchaseDate: d0, expiryDate: d0,
            status: .wasted, resolvedAt: .now, imageData: nil, createdAt: d0, price: nil
        )
        await vm.doAction(.dataResponse(.loaded(active: [], resolved: [wastedNoPrice])))
        #expect(vm.state.wastedCost == nil)
    }
}
