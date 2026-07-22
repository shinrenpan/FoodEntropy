import SwiftUI
import UIKit

@MainActor
final class FoodFormHostController: UIHostingController<FoodFormView> {

    private let viewModel: FoodFormViewModel

    init(mode: FoodFormMode, manager: SwiftDataManager) {
        self.viewModel = FoodFormViewModel(mode: mode, manager: manager)
        super.init(rootView: FoodFormView(viewModel: viewModel))
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

private extension FoodFormHostController {
    func handleRouter(_ router: FoodFormViewModel.Router) {
        switch router {
        case .close:
            AppRouter.shared.back(from: self)
        }
    }
}
