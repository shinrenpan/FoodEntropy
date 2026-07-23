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
            self?.handleRouter(router)
        }
    }
}

private extension SettingsHostController {
    func handleRouter(_ router: SettingsViewModel.Router) {
        switch router {
        case .openNotificationSettings:
            // iOS 16+ 深連到本 App 的「通知」設定子頁（模擬器可能只跳 Settings 首頁，真機才精準）。
            guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
            UIApplication.shared.open(url)   // 離開 App 到系統設定，非 App 內導航

        case let .openPrivacyPolicy(url):
            AppRouter.shared.sheet(SFSafariViewController(url: url), from: self)
        }
    }
}
