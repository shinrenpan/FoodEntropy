import SwiftUI

// 首頁的外層組裝。iPhone Duo 內螢幕寬大於高時，設定頁並排在右欄；
// 其餘情況（外螢幕、內螢幕直向、一般 iPhone、iOS 27.1 以下）只顯示首頁，與原本相同。
//
// `.split.axes(.horizontal)` 在高大於寬時只顯示 primary，所以首頁必須是 primary；
// 代價是 primary 固定在 leading 側，設定只能在右欄（2026-10-06 於 Duo 模擬器實測）。
// split 沒有指定 primary 落在哪一側的 API（27.1 SDK 只有 overlay 有 `overlayArrangementEdge`）。
// 半開時 ArrangementView 會自動讓出折線，這是不自己用 HStack 並排的理由。
struct HomeRootView: View {
    let homeViewModel: HomeViewModel
    let settingsViewModel: SettingsViewModel

    // 是否正在左右分割：設定頁並排時首頁不需要齒輪。
    //
    // 不讀 `splitArrangementAxis`：arrangement 的環境值只有子 view 讀得到，直接放進
    // primary 的 root view 讀到的是 nil（實測）。改照 `.split` 的文件規則自己判斷：
    // 寬大於高時左右分割。
    @State private var isSideBySide = false

    var body: some View {
        if #available(iOS 27.1, *) {
            ArrangementView {
                HomeView(viewModel: homeViewModel, showsSettingsButton: !isSideBySide)
            } secondary: {
                SettingsView(viewModel: settingsViewModel, isEmbedded: true)
            }
            .arrangementViewStyle(.split.axes(.horizontal))
            // 半開時兩欄會讓出折線，那段空白要跟兩欄同色，否則露出白底。
            .background(Color(.systemGroupedBackground))
            .onGeometryChange(for: Bool.self) { $0.size.width > $0.size.height } action: {
                isSideBySide = $0
            }
        } else {
            HomeView(viewModel: homeViewModel)
        }
    }
}
