import Foundation
import Testing
@testable import FoodEntropy

@MainActor
struct BucketListViewModelTests {
    private func makeManager() throws -> SwiftDataManager {
        try SwiftDataManager(inMemory: true)
    }

    // 注入 no-op NotificationService，避免測試打到系統通知。
    private func makeVM(
        bucket: ExpiryStatus = .nearExpiry,
        _ manager: SwiftDataManager
    ) -> BucketListViewModel {
        BucketListViewModel(
            bucket: bucket,
            manager: manager,
            notifications: NotificationService(active: false)
        )
    }

    private let d0 = Date(timeIntervalSince1970: 1_700_000_000)
    private func day(_ n: Int, from base: Date) -> Date {
        base.addingTimeInterval(86_400 * Double(n))
    }

    /// 建立一筆今天到期的食材（落在 nearExpiry 桶）。
    @discardableResult
    private func seedNearExpiry(_ manager: SwiftDataManager, name: String = "牛奶") throws -> FoodItem {
        try manager.create(name: name, purchaseDate: .now, expiryDate: .now)
    }


    /// 遷移自 `HomeViewModelTests` 的列動作測試共用：資料以 `d0`（過去時間）建立，
    /// 落在過期桶，因此取過期桶的 ViewModel。
    private func makeExpiredVM() throws -> (BucketListViewModel, SwiftDataManager) {
        let manager = try makeManager()
        return (makeVM(bucket: .expired, manager), manager)
    }

    // MARK: - 列動作（自 home-ui 遷移：首頁改為卡片堆疊後不再渲染食材列）

    @Test
    func `deleteDidTap 設定 pendingDeleteItem 不刪除`() async throws {
        let (vm, manager) = try makeExpiredVM()
        let item = try manager.create(name: "A", purchaseDate: d0, expiryDate: d0)
        await vm.doAction(.view(.onAppear))
        await vm.doAction(.view(.deleteDidTap(item)))
        #expect(vm.state.pendingDeleteItem == item)
        #expect(vm.state.items.count == 1)   // 尚未刪除
    }

    @Test
    func `deleteCancelled 清除 pendingDeleteItem`() async throws {
        let (vm, manager) = try makeExpiredVM()
        let item = try manager.create(name: "A", purchaseDate: d0, expiryDate: d0)
        await vm.doAction(.view(.deleteDidTap(item)))
        await vm.doAction(.view(.deleteCancelled))
        #expect(vm.state.pendingDeleteItem == nil)
    }

    @Test
    func `deleteConfirmed 刪除並重載`() async throws {
        let (vm, manager) = try makeExpiredVM()
        let item = try manager.create(name: "A", purchaseDate: d0, expiryDate: d0)
        await vm.doAction(.view(.onAppear))
        await vm.doAction(.view(.deleteDidTap(item)))
        await vm.doAction(.view(.deleteConfirmed))
        #expect(vm.state.pendingDeleteItem == nil)
        #expect(vm.state.items.isEmpty)
    }

    @Test
    func `consumeDidTap 移出清單`() async throws {
        let (vm, manager) = try makeExpiredVM()
        let item = try manager.create(name: "A", purchaseDate: d0, expiryDate: d0)
        await vm.doAction(.view(.onAppear))
        await vm.doAction(.view(.consumeDidTap(item)))
        #expect(vm.state.items.isEmpty)
    }

    @Test
    func `wasteDidTap 移出清單`() async throws {
        let (vm, manager) = try makeExpiredVM()
        let item = try manager.create(name: "A", purchaseDate: d0, expiryDate: d0)
        await vm.doAction(.view(.onAppear))
        await vm.doAction(.view(.wasteDidTap(item)))
        #expect(vm.state.items.isEmpty)
    }

    @Test
    func `extendDidTap 設定 extendingItem`() async throws {
        let (vm, manager) = try makeExpiredVM()
        let item = try manager.create(name: "A", purchaseDate: d0, expiryDate: d0)
        await vm.doAction(.view(.extendDidTap(item)))
        #expect(vm.state.extendingItem == item)
    }

    @Test
    func `extendCommitted 更新到期日並清除 extendingItem`() async throws {
        let (vm, manager) = try makeExpiredVM()
        let item = try manager.create(name: "A", purchaseDate: d0, expiryDate: d0)
        await vm.doAction(.view(.onAppear))
        await vm.doAction(.view(.extendDidTap(item)))
        let newExpiry = d0.addingTimeInterval(86_400 * 5)
        await vm.doAction(.view(.extendCommitted(newExpiry)))
        #expect(vm.state.extendingItem == nil)
        #expect(vm.state.items.first?.expiryDate == newExpiry)
    }

    // MARK: - 導航意圖

    @Test
    func `點列發出編輯意圖`() async throws {
        let manager = try makeManager()
        let item = try seedNearExpiry(manager)
        let vm = makeVM(manager)
        let recorder = BucketRouteRecorder()
        vm.onRoute = { [recorder] route in recorder.record(route) }
        await vm.doAction(.view(.rowDidTap(item)))
        #expect(recorder.toEditCount == 1)
        #expect(recorder.closeCount == 0)
    }

    @Test
    func `關閉發出關閉意圖`() async throws {
        let vm = try makeVM(makeManager())
        let recorder = BucketRouteRecorder()
        vm.onRoute = { [recorder] route in recorder.record(route) }
        await vm.doAction(.view(.doneDidTap))
        #expect(recorder.closeCount == 1)
    }

    // MARK: - 清單內容

    @Test
    func `onAppear 載入該桶的食材`() async throws {
        let manager = try makeManager()
        try seedNearExpiry(manager, name: "牛奶")
        let vm = makeVM(manager)
        await vm.doAction(.view(.onAppear))
        #expect(vm.state.items.count == 1)
        #expect(vm.state.items.first?.name == "牛奶")
    }

    @Test
    func `其他桶的食材不出現在本桶`() async throws {
        let manager = try makeManager()
        try seedNearExpiry(manager, name: "牛奶")
        // 過期桶的 ViewModel 不該看到 nearExpiry 的食材
        let vm = makeVM(bucket: .expired, manager)
        await vm.doAction(.view(.onAppear))
        #expect(vm.state.items.isEmpty)
    }
}

// MARK: - 導航記錄器

@MainActor
private final class BucketRouteRecorder {
    private(set) var toEditCount = 0
    private(set) var closeCount = 0

    func record(_ route: BucketListViewModel.Router) {
        switch route {
        case .toEdit: toEditCount += 1
        case .close: closeCount += 1
        }
    }
}
