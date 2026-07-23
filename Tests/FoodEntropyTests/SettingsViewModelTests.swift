import Foundation
import Testing
@testable import FoodEntropy

@MainActor
struct SettingsViewModelTests {
    private func makeVM(adsRemoved: Bool = false) -> (SettingsViewModel, UserDefaults) {
        let defaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        let vm = SettingsViewModel(store: StoreManager(adsRemoved: adsRemoved), defaults: defaults)
        return (vm, defaults)
    }

    @Test
    func `onAppear 反映已購買移除廣告`() async {
        let (vm, _) = makeVM(adsRemoved: true)
        await vm.doAction(.view(.onAppear))
        #expect(vm.state.adsRemoved == true)
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
    func `已購買移除廣告時再點購買不重複觸發`() async {
        let (vm, _) = makeVM(adsRemoved: true)
        await vm.doAction(.view(.onAppear))
        await vm.doAction(.view(.removeAdsDidTap))   // 已持有 → guard 擋下
        #expect(vm.state.adsRemoved == true)
        #expect(vm.state.purchaseInFlight == false)
    }
}
