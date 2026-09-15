import SwiftUI
import UIKit

@MainActor
final class HomeHostController: UIHostingController<HomeView> {

    private let viewModel: HomeViewModel
    private let manager: SwiftDataManager
    // 設定頁改由首頁建構並推入（見 home-ui），故需保留 store。
    private let store: StoreManager

    init(manager: SwiftDataManager, store: StoreManager) {
        self.manager = manager
        self.store = store
        self.viewModel = HomeViewModel(manager: manager, store: store)
        super.init(rootView: HomeView(viewModel: viewModel))
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

private extension HomeHostController {
    func handleRouter(_ router: HomeViewModel.Router) {
        switch router {
        case .toAdd:
            AppRouter.shared.to(FoodFormHostController(mode: .add, manager: manager), from: self)
        case .toSettings:
            AppRouter.shared.to(SettingsHostController(store: store), from: self)
        case let .toBucketList(bucket):
            // 包一層導覽控制器：清單內點食材要能把表單推在 sheet 自己的堆疊上
            // （見 navigation 的「push 落在呼叫者所屬的堆疊」）。
            let list = BucketListHostController(bucket: bucket, manager: manager)
            AppRouter.shared.sheet(UINavigationController(rootViewController: list), from: self)
        }
    }
}
