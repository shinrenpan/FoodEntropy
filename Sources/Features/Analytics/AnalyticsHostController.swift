import SwiftUI
import UIKit

// 分析為唯讀畫面，無導航需求 → 無 Router（最簡版 HostController）。
@MainActor
final class AnalyticsHostController: UIHostingController<AnalyticsView> {

    private let viewModel: AnalyticsViewModel

    init(manager: SwiftDataManager) {
        self.viewModel = AnalyticsViewModel(manager: manager)
        super.init(rootView: AnalyticsView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
