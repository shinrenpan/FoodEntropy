import Foundation
import Testing
@testable import FoodEntropy

@MainActor
struct SettingsViewModelTests {
    private func makeVM() -> (SettingsViewModel, UserDefaults) {
        let defaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        return (SettingsViewModel(defaults: defaults), defaults)
    }

    @Test
    func `iCloud 開啟寫入偏好並提示重啟`() async {
        let (vm, defaults) = makeVM()
        await vm.doAction(.view(.iCloudSyncToggled(true)))
        #expect(vm.state.iCloudSyncEnabled == true)
        #expect(vm.state.showRestartNotice == true)
        #expect(defaults.bool(forKey: AppPreferenceKey.iCloudSyncEnabled) == true)
    }

    @Test
    func `iCloud 關閉寫入 false`() async {
        let (vm, defaults) = makeVM()
        await vm.doAction(.view(.iCloudSyncToggled(true)))
        await vm.doAction(.view(.iCloudSyncToggled(false)))
        #expect(vm.state.iCloudSyncEnabled == false)
        #expect(defaults.bool(forKey: AppPreferenceKey.iCloudSyncEnabled) == false)
    }

    @Test
    func `移除廣告顯示即將推出`() async {
        let (vm, _) = makeVM()
        await vm.doAction(.view(.removeAdsDidTap))
        #expect(vm.state.showComingSoon == true)
    }

    @Test
    func `還原購買顯示即將推出`() async {
        let (vm, _) = makeVM()
        await vm.doAction(.view(.restoreDidTap))
        #expect(vm.state.showComingSoon == true)
    }
}
