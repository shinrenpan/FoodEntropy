import SwiftUI
import UIKit

@MainActor
final class HomeHostController: UIHostingController<HomeView> {

    private let viewModel: HomeViewModel
    private let manager: SwiftDataManager

    init(manager: SwiftDataManager, store: StoreManager) {
        self.manager = manager
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
        case let .toEdit(item):
            AppRouter.shared.to(FoodFormHostController(mode: .edit(item), manager: manager), from: self)
        }
    }
}
