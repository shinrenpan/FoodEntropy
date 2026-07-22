import SwiftUI
import UIKit
import UserNotifications

@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private static let homeTabIndex = 0

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .systemBackground   // 防止自訂轉場期間露出黑底
        window.rootViewController = makeRootTabBarController()
        window.makeKeyAndVisible()
        self.window = window

        UNUserNotificationCenter.current().delegate = self

        // 進入點 2：冷啟動 URL（必須在 makeKeyAndVisible() 之後）
        if let url = connectionOptions.urlContexts.first?.url,
           let deeplink = Deeplink(url: url) {
            handle(deeplink)
        }
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

    // 三 Tab 外殼；各分頁內容於 Phase 3 / 5 / 6 以正式 Feature HostController 替換。
    private func makeRootTabBarController() -> UITabBarController {
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [
            makeTab(title: "首頁", systemImage: "list.bullet", root: Phase0PlaceholderView(title: "首頁")),
            makeTab(title: "分析", systemImage: "chart.bar", root: Phase0PlaceholderView(title: "分析")),
            makeTab(title: "設定", systemImage: "gearshape", root: Phase0PlaceholderView(title: "設定")),
        ]
        return tabBarController
    }

    private func makeTab(
        title: String,
        systemImage: String,
        root: some View
    ) -> UINavigationController {
        let host = UIHostingController(rootView: root)
        host.navigationItem.title = title
        let nav = UINavigationController(rootViewController: host)
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
