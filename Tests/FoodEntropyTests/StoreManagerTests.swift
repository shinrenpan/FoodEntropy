import Foundation
import Testing
@testable import FoodEntropy

/// entitlement 改變時要廣播，值不變時不廣播（見 iap-remove-ads
/// 〈Entitlement changes reach every visible screen〉）。
@MainActor
struct StoreManagerTests {

    @Test("持有狀態改變時發出 didChangeNotification", arguments: [(false, true), (true, false)])
    func announcesChange(from initial: Bool, to owned: Bool) async {
        let store = StoreManager(adsRemoved: initial)
        await confirmation(expectedCount: 1) { announced in
            let token = NotificationCenter.default.addObserver(
                forName: StoreManager.didChangeNotification, object: nil, queue: nil
            ) { _ in announced() }
            store.applyOwnership(owned)
            NotificationCenter.default.removeObserver(token)
        }
        #expect(store.adsRemoved == owned)
    }

    @Test("對帳結果與現況相同時不發通知", arguments: [false, true])
    func silentWhenUnchanged(owned: Bool) async {
        let store = StoreManager(adsRemoved: owned)
        await confirmation(expectedCount: 0) { announced in
            let token = NotificationCenter.default.addObserver(
                forName: StoreManager.didChangeNotification, object: nil, queue: nil
            ) { _ in announced() }
            store.applyOwnership(owned)
            NotificationCenter.default.removeObserver(token)
        }
        #expect(store.adsRemoved == owned)
    }
}
