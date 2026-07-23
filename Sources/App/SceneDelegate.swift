import SwiftUI
import UIKit
import UserNotifications

@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private static let homeTabIndex = 0

    // 持有 manager 供前景時對帳通知排程。
    private var manager: SwiftDataManager?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let manager = makeManager()
        self.manager = manager

        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .systemBackground   // 防止自訂轉場期間露出黑底
        window.rootViewController = makeRootTabBarController(manager: manager)
        window.makeKeyAndVisible()
        self.window = window

        UNUserNotificationCenter.current().delegate = self

        // 進入點 2：冷啟動 URL（必須在 makeKeyAndVisible() 之後）
        if let url = connectionOptions.urlContexts.first?.url,
           let deeplink = Deeplink(url: url) {
            handle(deeplink)
        }
    }

    // 進前景時對帳通知排程（處理跨日、64 則上限、外部變動）。
    func sceneDidBecomeActive(_ scene: UIScene) {
        guard let manager else { return }
        Task { await NotificationService.shared.reconcile(activeFoods: manager.fetchActiveFoods()) }
    }

    // 進入點 1：前景 / 背景 URL Scheme
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url,
              let deeplink = Deeplink(url: url) else { return }
        handle(deeplink)
    }

    // MARK: - Deeplink 處理

    // v1：唯一目標 .home → 切首頁 Tab（present-style 目標未來再擴充）。
    private func handle(_ deeplink: Deeplink) {
        switch deeplink {
        case .home:
            (window?.rootViewController as? UITabBarController)?.selectedIndex = Self.homeTabIndex
        }
    }

    // MARK: - 導航裝配（Phase 2）

    // 三 Tab 裝配。
    private func makeRootTabBarController(manager: SwiftDataManager) -> UITabBarController {
        let homeTitle = String(localized: "首頁")
        let analyticsTitle = String(localized: "分析")
        let settingsTitle = String(localized: "設定")

        let home = HomeHostController(manager: manager)
        home.navigationItem.title = homeTitle

        let analytics = AnalyticsHostController(manager: manager)
        analytics.navigationItem.title = analyticsTitle

        let settings = SettingsHostController()
        settings.navigationItem.title = settingsTitle

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [
            wrapInTab(home, title: homeTitle, systemImage: "list.bullet"),
            wrapInTab(analytics, title: analyticsTitle, systemImage: "chart.bar"),
            wrapInTab(settings, title: settingsTitle, systemImage: "gearshape"),
        ]
        #if DEBUG
        // 開發用：以 INITIAL_TAB=<index> 啟動時定位初始分頁。
        if let raw = ProcessInfo.processInfo.environment["INITIAL_TAB"], let index = Int(raw) {
            tabBarController.selectedIndex = index
        }
        #endif
        return tabBarController
    }

    // Composition root：依 iCloud 開關偏好建立 SwiftDataManager（02-architecture §6）。
    private func makeManager() -> SwiftDataManager {
        let cloudKitEnabled = UserDefaults.standard.bool(forKey: AppPreferenceKey.iCloudSyncEnabled)
        do {
            let manager = try SwiftDataManager(cloudKitEnabled: cloudKitEnabled)
            #if DEBUG
            // 開發用：以 SEED_MOCKS=1 啟動時，清單為空則塞入 mock 食材。
            if ProcessInfo.processInfo.environment["SEED_MOCKS"] == "1",
               manager.fetchActiveFoods().isEmpty {
                for mock in FoodItem.mocks {
                    manager.create(
                        name: mock.name,
                        purchaseDate: mock.purchaseDate,
                        expiryDate: mock.expiryDate,
                        imageData: mock.imageData
                    )
                }
                // 給分析頁一些已處理紀錄（4 吃掉、1 丟棄 → 浪費率 20%）
                for name in ["已吃-優格", "已吃-吐司", "已吃-香蕉", "已吃-起司"] {
                    let f = manager.create(name: name, purchaseDate: .now, expiryDate: .now)
                    manager.markConsumed(id: f.id)
                }
                let wastedFood = manager.create(name: "丟棄-菠菜", purchaseDate: .now, expiryDate: .now)
                manager.markWasted(id: wastedFood.id)
            }
            #endif
            return manager
        } catch {
            fatalError("無法建立 SwiftDataManager：\(error)")
        }
    }

    private func wrapInTab(
        _ root: UIViewController,
        title: String,
        systemImage: String
    ) -> UINavigationController {
        let nav = UINavigationController(rootViewController: root)
        nav.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: systemImage), selectedImage: nil)
        return nav
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
