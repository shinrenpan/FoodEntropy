import SwiftUI

// 首頁的外層組裝。寬大於高時（iPhone Duo 內螢幕橫向），設定並排在左、首頁留在右——
// Apple Mail 在 iPhone Duo 的模型：闔上時看到的內容，翻開後在 trailing 側。
// 其餘情況（外螢幕、內螢幕直向、一般 iPhone）只顯示首頁，與原本相同。
//
// 不用 ArrangementView：split 沒有指定 primary 落在哪一側的 API（primary 固定 leading）。
// 不用 UISplitViewController：column 樣式收合時把首頁推到設定的堆疊上，classic 寫法在
// iOS 27 SDK 會斷言失敗（兩者皆實測）。改照 Apple「Prepare」頁的建議自己判斷寬高，
// 並依官方 Q&A「讀 reserved regions 自行調整」讓兩欄避開折線。
struct HomeRootView: View {
    let homeViewModel: HomeViewModel
    let settingsViewModel: SettingsViewModel

    var body: some View {
        // 量的是外層給的空間：GeometryReader 的大小只取決於提案，不受欄寬回頭影響
        //（量 HStack 本身會被固定欄寬撐住，轉直向時退不回單欄——實測）。
        GeometryReader { proxy in
            let layout = SideBySideLayout(proxy: proxy)

            // 首頁永遠是 HStack 的第二個子 view，只增減左欄：切換時首頁不會被重建
            //（不重跑 onAppear、不丟捲動位置、不關掉開著的 sheet）。兩欄都給確定寬度：
            // 只給 maxWidth: .infinity 時，轉換後的分配不固定（實測出現過 2:1）。
            HStack(spacing: layout.gap) {
                if layout.isSideBySide {
                    SettingsView(viewModel: settingsViewModel, isEmbedded: true)
                        .frame(width: layout.leadingWidth)
                }
                HomeView(viewModel: homeViewModel, showsSettingsButton: !layout.isSideBySide)
                    .frame(width: layout.trailingWidth)
            }
        }
        // 半開時兩欄之間讓出的折線空白要跟兩欄同色，否則露出白底。
        .background(Color(.systemGroupedBackground))
    }
}

// 兩欄的寬度與間距。
//
// 有啟用中的直向折線（半開）時，兩欄分別停在折線兩側、中間讓出折線的寬度；
// 平放全開時系統不回報啟用中的折線，就各占一半。
private struct SideBySideLayout {
    let isSideBySide: Bool
    let leadingWidth: CGFloat
    let trailingWidth: CGFloat
    let gap: CGFloat

    init(proxy: GeometryProxy) {
        let size = proxy.size
        isSideBySide = size.width > size.height
        guard isSideBySide else {
            leadingWidth = 0
            trailingWidth = size.width
            gap = 0
            return
        }

        if let fold = Self.verticalFold(in: proxy), fold.frame.minX > 0, fold.frame.maxX < size.width {
            if fold.isActive {
                // 半開：兩欄停在折線兩側，讓出折線寬度。
                leadingWidth = fold.frame.minX
                gap = fold.frame.width
                trailingWidth = size.width - fold.frame.maxX
            } else {
                // 平放全開：分界仍對準折線中央，不用「容器寬的一半」。容器扣掉了右側
                // 狀態列，一半不等於實體折線；改用一半的話，半開↔全開切換時卡牌欄會
                // 一次跳 60pt 左右（實測）。對準折線則只差讓出的那半段。
                leadingWidth = fold.frame.midX
                gap = 0
                trailingWidth = size.width - fold.frame.midX
            }
        } else {
            leadingWidth = size.width / 2
            gap = 0
            trailingWidth = size.width / 2
        }
    }

    // 直向（高大於寬）的折線才影響左右分欄；橫向的折線與這個版面無關。
    // 含未啟用的：平放全開時折線不啟用，但位置仍要拿來當分界。
    private static func verticalFold(in proxy: GeometryProxy) -> (frame: CGRect, isActive: Bool)? {
        guard #available(iOS 27.1, *) else { return nil }
        return proxy.reservedRegions(kind: .division, options: .includeInactive)
            .first { $0.frame.height > $0.frame.width }
            .map { ($0.frame, $0.isActive) }
    }
}

