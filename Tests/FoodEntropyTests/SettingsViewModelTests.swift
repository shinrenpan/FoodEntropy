import Foundation
import Testing
@testable import FoodEntropy

@MainActor
struct SettingsViewModelTests {
    private func makeVM() -> (SettingsViewModel, UserDefaults, SwiftDataManager) {
        let defaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        let manager = try! SwiftDataManager(inMemory: true)
        return (SettingsViewModel(manager: manager, defaults: defaults), defaults, manager)
    }

    @Test
    func `iCloud 開啟寫入偏好並提示重啟`() async {
        let (vm, defaults, _) = makeVM()
        await vm.doAction(.view(.iCloudSyncToggled(true)))
        #expect(vm.state.iCloudSyncEnabled == true)
        #expect(vm.state.showRestartNotice == true)
        #expect(defaults.bool(forKey: AppPreferenceKey.iCloudSyncEnabled) == true)
    }

    @Test
    func `iCloud 關閉寫入 false`() async {
        let (vm, defaults, _) = makeVM()
        await vm.doAction(.view(.iCloudSyncToggled(true)))
        await vm.doAction(.view(.iCloudSyncToggled(false)))
        #expect(vm.state.iCloudSyncEnabled == false)
        #expect(defaults.bool(forKey: AppPreferenceKey.iCloudSyncEnabled) == false)
    }

    @Test
    func `移除廣告顯示即將推出`() async {
        let (vm, _, _) = makeVM()
        await vm.doAction(.view(.removeAdsDidTap))
        #expect(vm.state.showComingSoon == true)
    }

    @Test
    func `還原購買顯示即將推出`() async {
        let (vm, _, _) = makeVM()
        await vm.doAction(.view(.restoreDidTap))
        #expect(vm.state.showComingSoon == true)
    }

    @Test
    func `清除歷史統計刪除已處理紀錄`() async {
        let (vm, _, manager) = makeVM()
        let d0 = Date(timeIntervalSince1970: 1_700_000_000)
        let a = manager.create(name: "吃了", purchaseDate: d0, expiryDate: d0)
        manager.markConsumed(id: a.id)
        #expect(manager.fetchResolvedFoods().count == 1)

        await vm.doAction(.view(.clearHistoryDidTap))
        #expect(vm.state.showClearHistoryConfirm == true)
        await vm.doAction(.view(.clearHistoryConfirmed))
        #expect(vm.state.showClearHistoryConfirm == false)
        #expect(manager.fetchResolvedFoods().isEmpty)
    }
}
