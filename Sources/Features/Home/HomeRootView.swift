import SwiftUI

// 首頁的外層組裝（見 home-ui〈A wide container shows settings beside the home screen〉）。
// 外層給的空間寬大於高時（只有 iPhone Duo 內螢幕橫向會這樣），設定在左、首頁在右——
// Apple Mail 的模型：闔上時看到的內容，翻開後在 trailing 側。其餘情況只顯示首頁。
//
// 為什麼不用系統容器（實測，詳見 adapt-iphone-duo 的 design）：ArrangementView 的 split
// 沒有指定 primary 落在哪一側的 API；UISplitViewController 收合時把首頁推到設定的堆疊上；
// UIArrangementViewController 會讓所有 iOS 27.1 iPhone 走一條目前測不到的路徑。
struct HomeRootView: View {
    let homeViewModel: HomeViewModel
    let settingsViewModel: SettingsViewModel

    var body: some View {
        // 量的是外層給的空間：GeometryReader 的大小只取決於提案，不受欄寬回頭影響。
        // 若改量 HStack 本身，轉直向時欄寬還是上一輪的值，會把它撐得比螢幕寬、
        // 量到的仍是寬大於高而退不回單欄（實測）。
        GeometryReader { proxy in
            let layout = SideBySideLayout(size: proxy.size, fold: Self.verticalFold(in: proxy))

            // 首頁永遠是 HStack 的最後一個子 view，只增減左欄，所以切換時首頁不會被重建
            // （捲動位置、開著的 sheet、已載入的狀態都保留）。兩欄都給確定寬度：只給
            // maxWidth: .infinity 時轉換後的分配不固定（實測出現過 2:1）。
            HStack(spacing: layout.gap) {
                if layout.isSideBySide {
                    SettingsView(viewModel: settingsViewModel, isEmbedded: true)
                        .frame(width: layout.leadingWidth)
                }
                HomeView(viewModel: homeViewModel, showsSettingsButton: !layout.isSideBySide)
                    .frame(width: layout.trailingWidth)
            }
        }
        // 半開時兩欄之間讓出的折線空白要與兩欄同色，否則露出 window 的白底。
        .background(Color(.systemGroupedBackground))
    }

    // 直向（高大於寬）的折線才影響左右分欄。含未啟用的：平放時折線不啟用，但位置仍
    // 要拿來當分界。reservedRegions 只在 iOS 27.1 起存在，低版本視為沒有折線。
    private static func verticalFold(in proxy: GeometryProxy) -> (frame: CGRect, isActive: Bool)? {
        guard #available(iOS 27.1, *) else { return nil }
        return proxy.reservedRegions(kind: .division, options: .includeInactive)
            .first { $0.frame.height > $0.frame.width }
            .map { ($0.frame, $0.isActive) }
    }
}
