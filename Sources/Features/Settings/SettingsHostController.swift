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

    // 被推入的設定頁遇到空間變寬（iPhone Duo 翻開或內螢幕轉橫）時退回首頁：那時首頁
    // 會把設定並排在左欄（見 home-ui〈A pushed settings screen yields to the settings
    // column〉），留著這頁就同時有兩份設定。轉場完成後才退，避免在尺寸變化中途改動 stack。
    // 判斷與首頁的分欄條件共用 SideBySideLayout.isWide。注意量的尺寸不同：這裡是整個
    // 畫面，首頁量的是扣掉導覽列與安全區後的空間。Duo 實測的窄（669×951）與寬
    // （867×553）都遠離寬高相等，兩邊結論一致；接近正方形的視窗（日後解除直立鎖定
    // 或多視窗）才可能不同步，屆時改用同一種尺寸判斷。
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard SideBySideLayout.isWide(size) else { return }
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self else { return }
            AppRouter.shared.back(from: self, animated: false)
        }
    }
}

extension SettingsHostController {
    // 設定也會嵌在首頁旁並排顯示（iPhone Duo，見 HomeRootView），那時沒有自己的
    // HostController，由首頁的 HostController 代為執行導航；兩條路徑共用這一份。
    //
    // 已知架構債（MVVMC，2026-10-07）：首頁 host 跨 feature 呼叫這個 static。解法已由
    // MVVMC Experiments/PaneProbe 驗證——每欄改為完整 HostController。等一般 iPhone 能
    // 測 iOS 27.1、改用 UIArrangementViewController 容器時一併移除。
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
