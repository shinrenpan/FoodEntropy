import SwiftUI
import UIKit
import UserNotifications

@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    // 持有 manager 供前景時對帳通知排程。
    private var manager: SwiftDataManager?

    // 持有 store 供 IAP entitlement 對帳與交易更新監聽（單一真相來源）。
    private var store: StoreManager?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let manager = makeManager()
        self.manager = manager

        let store: StoreManager
        #if DEBUG
        if ProcessInfo.processInfo.environment["SCREENSHOT_MODE"] == "1" {
            store = StoreManager(adsRemoved: true)   // 上架截圖用：隱藏廣告，畫面乾淨
        } else {
            store = StoreManager()
            Task { await store.start() }
        }
        #else
        store = StoreManager()
        Task { await store.start() }   // 載入商品 + 對帳 entitlement + 監聽交易更新
        #endif
        self.store = store

        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .systemBackground   // 防止自訂轉場期間露出黑底
        window.rootViewController = makeRootNavigationController(manager: manager, store: store)
        window.makeKeyAndVisible()
        self.window = window

        UNUserNotificationCenter.current().delegate = self

        // 進入點 2：冷啟動 URL（必須在 makeKeyAndVisible() 之後）
        if let url = connectionOptions.urlContexts.first?.url,
           let deeplink = Deeplink(url: url) {
            handle(deeplink)
        }

        // 進入點 4：App Intents 放下的待處理目標（冷啟動時 scene 尚未存在）。
        drainPendingDeeplink()

        // app 已在前景時 App Intents 才放目標的情況（例如從 app 內下拉 Spotlight）
        // 沒有生命週期轉換可依附，靠通知補上。
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pendingDeeplinkDidSet),
            name: PendingDeeplink.didSetNotification,
            object: nil
        )
    }

    // 進前景時對帳通知排程（處理跨日、64 則上限、外部變動）。
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Siri 觸發 Intent 後 app 被帶到前景，目標在此取用。
        drainPendingDeeplink()
        guard let manager else { return }
        Task { await NotificationService.shared.reconcile(activeFoods: manager.fetchActiveFoods()) }
    }

    @objc private func pendingDeeplinkDidSet() {
        drainPendingDeeplink()
    }

    private func drainPendingDeeplink() {
        guard let deeplink = PendingDeeplink.take() else { return }
        handle(deeplink)
    }

    // 進入點 1：前景 / 背景 URL Scheme
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url,
              let deeplink = Deeplink(url: url) else { return }
        handle(deeplink)
    }

    // MARK: - Deeplink 處理

    private func handle(_ deeplink: Deeplink) {
        guard let nav = window?.rootViewController as? UINavigationController else { return }

        switch deeplink {
        case .home:
            // 沒有分頁可切，回到 stack 根部即是「首頁」。
            // 經由 AppRouter 而非直接操作 stack：導航一律收在中樞（見 navigation）。
            guard let top = nav.topViewController else { return }
            AppRouter.shared.backToRoot(from: top, animated: false)
        case let .foodItem(id):
            showFoodItem(id: id, in: nav)
        }
    }

    // Spotlight 點擊食材結果與 Siri 的「開啟某食材」都走這裡（見 app-intents）。
    // 找不到就停在首頁——食材可能已被標記或刪除，那不是錯誤，只是目標不在了。
    private func showFoodItem(id: UUID, in nav: UINavigationController) {
        guard let home = nav.viewControllers.first else { return }
        guard let manager,
              let item = manager.fetchActiveFoods().first(where: { $0.id == id })
        else {
            // 目標不在了（已使用／丟棄／刪除）。回到首頁清單而非停在原畫面：
            // 使用者點的是「開啟某食材」，把他留在別的畫面等於那一下沒有作用
            // （見 navigation 的「Following a link to an item that is gone」）。
            AppRouter.shared.backToRoot(from: nav.topViewController ?? home, animated: false)
            return
        }

        // 回到首頁再呈現目標，交給 AppRouter 以單次 stack 設定完成。
        // 不可在此自行 pop 再 push：UIKit 會丟棄前一次導航尚未落定期間的 push，
        // 使用者被彈回首頁而目標從未出現（見 fix-deeplink-dropped-push）。
        // 這也讓設定頁與既有的編輯表單一併被收掉，不必在此判斷 stack 深度。
        AppRouter.shared.resetTo(FoodFormHostController(mode: .edit(item), manager: manager), from: home, animated: false)
    }

    // MARK: - 導航裝配（Phase 2）

    // 單一 navigation stack，root 為首頁；設定由首頁推入（見 app-shell / home-ui）。
    // 標題由各自的 SwiftUI View 設定，組裝點只負責結構。
    private func makeRootNavigationController(manager: SwiftDataManager, store: StoreManager) -> UINavigationController {
        let home = HomeHostController(manager: manager, store: store)
        return UINavigationController(rootViewController: home)
    }

    // Composition root：取用 process 層級的共用連線（見 persistence）。
    // 不自行建立——App Intents 在無 scene 時也要取到同一份連線，兩個 container
    // 指向同一份 store 會讓 Intent 的寫入不反映到畫面既有的 context。
    // 偏好讀取與三層降級都在該取用點內完成（見 icloud-sync）。
    private func makeManager() -> SwiftDataManager {
        let manager = SwiftDataManager.shared
        #if DEBUG
        // 開發用：以 SEED_MOCKS=1 啟動時，清單為空則塞入 mock 食材。
        if ProcessInfo.processInfo.environment["SEED_MOCKS"] == "1",
           manager.fetchActiveFoods().isEmpty {
            for mock in FoodItem.mocks {
                _ = try? manager.create(
                    name: mock.name,
                    purchaseDate: mock.purchaseDate,
                    expiryDate: mock.expiryDate,
                    imageData: mock.imageData,
                    price: mock.price
                )
            }
            // 給首頁的浪費統計一些已處理紀錄（4 吃掉、1 丟棄 → 浪費率 20%）
            for name in ["已吃-優格", "已吃-吐司", "已吃-香蕉", "已吃-起司"] {
                let f = try? manager.create(name: name, purchaseDate: .now, expiryDate: .now)
                if let f { try? manager.markConsumed(id: f.id) }
            }
            if let wastedFood = try? manager.create(name: "丟棄-菠菜", purchaseDate: .now, expiryDate: .now) {
                try? manager.markWasted(id: wastedFood.id)
            }
        }
        #endif
        return manager
    }

}

// MARK: - UNUserNotificationCenterDelegate

extension SceneDelegate: UNUserNotificationCenterDelegate {
    // 進入點 3：Push / Local 通知點擊（全狀態通用）— nonisolated，用 Task 跳回主執行緒
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }
        let userInfo = response.notification.request.content.userInfo
        // 通知 payload 慣例：{ "deeplink": "foodentropy://home" }；無 payload 則預設回首頁
        let urlString = userInfo["deeplink"] as? String ?? "foodentropy://home"
        guard let url = URL(string: urlString),
              let deeplink = Deeplink(url: url) else { return }
        Task { @MainActor in self.handle(deeplink) }
    }

    // App 在前景時仍顯示通知橫幅（到期提醒即使正在使用也該看到）
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
