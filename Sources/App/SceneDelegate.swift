import SwiftUI
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        // 自訂轉場期間避免露出黑底（mvvmc-navigation）
        window.backgroundColor = .systemBackground
        window.rootViewController = makeRootTabBarController()
        window.makeKeyAndVisible()
        self.window = window

        // TODO: Phase 2 — 冷啟動 deeplink 於 makeKeyAndVisible() 之後處理
    }

    // MARK: - Phase 0 骨架

    // 三 Tab 外殼；各分頁內容於 Phase 3 / 5 / 6 以正式 Feature（HostController）替換。
    // 正式的 AppRouter / Deeplink 導航地基於 Phase 2 接上。
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
        let nav = UINavigationController(rootViewController: host)
        nav.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: systemImage), selectedImage: nil)
        host.navigationItem.title = title
        return nav
    }
}
