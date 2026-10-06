import SafariServices
import SwiftUI
import UIKit

@MainActor
final class SettingsHostController: UIHostingController<SettingsView> {

    private let viewModel: SettingsViewModel

    init(store: StoreManager) {
        self.viewModel = SettingsViewModel(store: store)
        super.init(rootView: SettingsView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.onRoute = { [weak self] router in
            guard let self else { return }
            Self.handle(router, from: self)
        }
    }

    // 被推入的設定頁遇到 iPhone Duo 翻開（或內螢幕轉橫）時退回首頁：首頁那時會把
    // 設定並排在右欄（見 HomeRootView），留著這頁就同時有兩份設定。轉場完成後才退，
    // 避免在尺寸變化中途改動 stack。規則須與 HomeRootView 的分割條件一致。
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard size.width > size.height else { return }
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self else { return }
            AppRouter.shared.back(from: self, animated: false)
        }
    }
}

extension SettingsHostController {
    // 設定頁也會並排嵌在首頁裡（iPhone Duo，見 HomeRootView），那時由首頁的
    // HostController 代為處理導航；兩條路徑共用這一份，不各寫一套。
    static func handle(_ router: SettingsViewModel.Router, from source: UIViewController) {
        switch router {
        case .openNotificationSettings:
            // iOS 16+ 深連到本 App 的「通知」設定子頁（模擬器可能只跳 Settings 首頁，真機才精準）。
            guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
            UIApplication.shared.open(url)   // 離開 App 到系統設定，非 App 內導航

        case let .openPrivacyPolicy(url):
            AppRouter.shared.sheet(SFSafariViewController(url: url), from: source)
        }
    }
}
