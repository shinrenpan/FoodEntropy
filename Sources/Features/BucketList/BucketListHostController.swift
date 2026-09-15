import SwiftUI
import UIKit

// 單一分桶清單的 C 層（mvvmc-hostcontroller）。
//
// 由首頁以 sheet 呈現，且呈現時包在一層 UINavigationController 內——
// AppRouter 一律從 source view controller 動態取得導覽控制器，所以
// 由此發起的推入會落在 sheet 自己的堆疊上，離開表單後退回清單而非首頁
// （見 navigation 的「push 落在呼叫者所屬的堆疊」）。
@MainActor
final class BucketListHostController: UIHostingController<BucketListView> {

    private let viewModel: BucketListViewModel
    private let manager: SwiftDataManager

    init(bucket: ExpiryStatus, manager: SwiftDataManager) {
        self.manager = manager
        self.viewModel = BucketListViewModel(bucket: bucket, manager: manager)
        super.init(rootView: BucketListView(viewModel: viewModel))
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

private extension BucketListHostController {
    func handleRouter(_ router: BucketListViewModel.Router) {
        switch router {
        case let .toEdit(item):
            // 推入 sheet 自己的堆疊，不是首頁的。
            AppRouter.shared.to(FoodFormHostController(mode: .edit(item), manager: manager), from: self)
        case .close:
            dismiss(animated: true)
        }
    }
}
