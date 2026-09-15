import Foundation
import Testing
@testable import FoodEntropy

@MainActor
struct HomeViewModelTests {
    private func makeVM(adsRemoved: Bool = false) throws -> (HomeViewModel, SwiftDataManager) {
        let manager = try SwiftDataManager(inMemory: true)
        let vm = HomeViewModel(manager: manager, store: StoreManager(adsRemoved: adsRemoved))
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
        try manager.create(name: "牛奶", purchaseDate: d0, expiryDate: d0)
        await vm.doAction(.view(.onAppear))
        #expect(vm.state.items.count == 1)
        #expect(vm.state.items.first?.name == "牛奶")
    }

    @Test
    func `loaded 計算浪費統計`() async throws {
        let (vm, manager) = try makeVM()
        let a = try manager.create(name: "A", purchaseDate: d0, expiryDate: d0)
        let b = try manager.create(name: "B", purchaseDate: d0, expiryDate: d0)
        let c = try manager.create(name: "C", purchaseDate: d0, expiryDate: d0)
        try manager.markConsumed(id: a.id)
        try manager.markConsumed(id: b.id)
        try manager.markWasted(id: c.id)
        await vm.doAction(.dataResponse(.loaded(active: [], resolved: manager.fetchResolvedFoods())))
        #expect(vm.state.consumedCount == 2)
        #expect(vm.state.wastedCount == 1)
        #expect(vm.state.hasHistory == true)
    }

    @Test
    func `清除歷史統計刪除已處理並歸零`() async throws {
        let (vm, manager) = try makeVM()
        let a = try manager.create(name: "吃了", purchaseDate: d0, expiryDate: d0)
        try manager.markConsumed(id: a.id)
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

    // MARK: - 導航（remove-tab-bar）

    @Test
    func `齒輪點擊發出前往設定意圖`() async throws {
        let (vm, _) = try makeVM()
        let recorder = HomeRouteRecorder()
        vm.onRoute = { [recorder] route in recorder.record(route) }
        await vm.doAction(.view(.settingsDidTap))
        #expect(recorder.toSettingsCount == 1)
    }
    // MARK: - 卡片堆疊（restyle-home-as-card-stack）

    /// 讓三個分桶都有內容，以便分辨「空桶不開清單」與「非空桶才開」。
    private func loadAllBuckets(_ vm: HomeViewModel) async {
        await vm.doAction(.dataResponse(.loaded(active: FoodItem.mocks, resolved: [])))
    }

    private func recording(_ vm: HomeViewModel) -> HomeRouteRecorder {
        let recorder = HomeRouteRecorder()
        vm.onRoute = { [recorder] route in recorder.record(route) }
        return recorder
    }

    @Test
    func `點未選中的卡只改變選中身分`() async throws {
        let (vm, _) = try makeVM()
        await loadAllBuckets(vm)
        let recorder = recording(vm)
        vm.state.selectedCard = .current
        await vm.doAction(.view(.cardDidTap(.nearExpiry)))
        #expect(vm.state.selectedCard == .nearExpiry)
        #expect(recorder.toBucketListCount == 0)   // 第一次點只移到前面，不開清單
    }

    @Test
    func `點已選中的非空分桶卡才發出前往清單的意圖`() async throws {
        let (vm, _) = try makeVM()
        await loadAllBuckets(vm)
        let recorder = recording(vm)
        vm.state.selectedCard = .nearExpiry
        await vm.doAction(.view(.cardDidTap(.nearExpiry)))
        #expect(recorder.toBucketListCount == 1)
        #expect(recorder.lastBucket == .nearExpiry)
    }

    @Test
    func `點已選中的摘要卡不發出前往清單的意圖`() async throws {
        let (vm, _) = try makeVM()
        await loadAllBuckets(vm)
        let recorder = recording(vm)
        for card in [HomeCard.current, .waste] {
            vm.state.selectedCard = card
            await vm.doAction(.view(.cardDidTap(card)))
        }
        #expect(recorder.toBucketListCount == 0)
    }

    @Test
    func `點已選中但為空的分桶卡不發出前往清單的意圖`() async throws {
        let (vm, _) = try makeVM()
        // 只有 fresh 有內容 → expired 與 nearExpiry 皆為空桶
        let fresh = FoodItem.mocks.filter { $0.expiryStatus() == .fresh }
        await vm.doAction(.dataResponse(.loaded(active: fresh, resolved: [])))
        let recorder = recording(vm)
        vm.state.selectedCard = .expired
        await vm.doAction(.view(.cardDidTap(.expired)))
        #expect(recorder.toBucketListCount == 0)
    }

    @Test
    func `選中的分桶變空時自動移到最急迫的非空桶`() async throws {
        let (vm, _) = try makeVM()
        await loadAllBuckets(vm)
        vm.state.selectedCard = .expired
        // 重新載入一份不含過期項的資料 → 過期桶變空
        let notExpired = FoodItem.mocks.filter { $0.expiryStatus() != .expired }
        await vm.doAction(.dataResponse(.loaded(active: notExpired, resolved: [])))
        #expect(vm.state.selectedCard == .nearExpiry)
    }
}

// MARK: - 導航記錄器

@MainActor
private final class HomeRouteRecorder {
    private(set) var toSettingsCount = 0
    private(set) var toAddCount = 0
    private(set) var toBucketListCount = 0
    private(set) var lastBucket: ExpiryStatus?

    func record(_ route: HomeViewModel.Router) {
        switch route {
        case .toAdd: toAddCount += 1
        case .toSettings: toSettingsCount += 1
        case let .toBucketList(bucket):
            toBucketListCount += 1
            lastBucket = bucket
        }
    }
}
