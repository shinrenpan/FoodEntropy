import SwiftUI

// Phase 0 骨架佔位。Phase 3（首頁）/ 5（分析）/ 6（設定）會以正式 Feature View 取代。
struct Phase0PlaceholderView: View {
    let title: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "fork.knife")
        } description: {
            Text("Phase 0 骨架，待實作")
        }
    }
}

#Preview {
    Phase0PlaceholderView(title: "首頁")
}
