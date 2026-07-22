import SwiftUI
import UIKit

// Phase 4 佔位：僅提供可 push 的目標，讓首頁新增 / 編輯導航可運作。
// Phase 4 會換成正式 FoodFormViewModel + FoodFormView（03-screens/form.md）。
@MainActor
final class FoodFormHostController: UIHostingController<FoodFormPlaceholderView> {
    init(mode: FoodFormMode) {
        super.init(rootView: FoodFormPlaceholderView(mode: mode))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct FoodFormPlaceholderView: View {
    let mode: FoodFormMode

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "square.and.pencil")
        } description: {
            Text("Phase 4 實作")
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var title: String {
        switch mode {
        case .add: "新增食材"
        case .edit: "編輯食材"
        }
    }
}
