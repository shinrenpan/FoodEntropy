import CoreGraphics
import Testing
@testable import FoodEntropy

/// 首頁兩欄的欄寬計算（見 home-ui〈A wide container shows settings beside the home
/// screen〉）。期望值取自 2026-10-07 在 iPhone Duo 模擬器（Xcode 27.1 RC，iOS 27.1）
/// 實測的容器與折線：容器 867×553pt、直向折線 455–495pt（寬 40）。畫面讀值是整數
/// 截斷，所以容器寬用 867 時期望值依實際算術給出，並以 1pt 容差對照實測。
struct SideBySideLayoutTests {

    private let fold = CGRect(x: 455, y: 0, width: 40, height: 553)

    @Test("高大於寬時只有首頁一欄")
    func narrowIsSingleColumn() {
        let layout = SideBySideLayout(size: CGSize(width: 669, height: 951), fold: nil)
        #expect(!layout.isSideBySide)
        #expect(layout.leadingWidth == 0)
        #expect(layout.gap == 0)
        #expect(layout.trailingWidth == 669)
    }

    @Test("寬高相等時不算寬，只有一欄")
    func squareIsSingleColumn() {
        let layout = SideBySideLayout(size: CGSize(width: 500, height: 500), fold: nil)
        #expect(!layout.isSideBySide)
        #expect(layout.trailingWidth == 500)
    }

    @Test("半開（折線啟用）時兩欄停在折線兩側、讓出折線寬度")
    func activeFoldLeavesGap() {
        let layout = SideBySideLayout(size: CGSize(width: 867, height: 553), fold: (fold, true))
        #expect(layout.isSideBySide)
        #expect(layout.leadingWidth == 455)
        #expect(layout.gap == 40)
        #expect(layout.trailingWidth == 372)   // 實測讀值 371（截斷）
    }

    @Test("平放（折線未啟用）時分界在折線中央，不留間距")
    func inactiveFoldSplitsAtCentre() {
        let layout = SideBySideLayout(size: CGSize(width: 867, height: 553), fold: (fold, false))
        #expect(layout.isSideBySide)
        #expect(layout.leadingWidth == 475)
        #expect(layout.gap == 0)
        #expect(layout.trailingWidth == 392)   // 實測讀值 391（截斷）
    }

    @Test("沒有折線時各占一半")
    func noFoldSplitsInHalf() {
        let layout = SideBySideLayout(size: CGSize(width: 800, height: 400), fold: nil)
        #expect(layout.isSideBySide)
        #expect(layout.leadingWidth == 400)
        #expect(layout.gap == 0)
        #expect(layout.trailingWidth == 400)
    }

    /// 分割畫面時折線可能只剩貼著邊緣的一條細縫，不能拿來當分界。
    @Test("折線碰到容器邊緣時視為沒有折線", arguments: [
        CGRect(x: 0, y: 0, width: 20, height: 400),
        CGRect(x: 780, y: 0, width: 20, height: 400),
    ])
    func foldAtEdgeIsIgnored(edge: CGRect) {
        let layout = SideBySideLayout(size: CGSize(width: 800, height: 400), fold: (edge, true))
        #expect(layout.leadingWidth == 400)
        #expect(layout.gap == 0)
        #expect(layout.trailingWidth == 400)
    }

    /// 推入的設定頁在變寬時退回（見 home-ui〈A pushed settings screen yields to the
    /// settings column〉）用的是同一個判斷，兩處必須一致。
    @Test("寬大於高才算寬", arguments: [
        (CGSize(width: 867, height: 553), true),
        (CGSize(width: 669, height: 951), false),
        (CGSize(width: 500, height: 500), false),
    ])
    func isWide(size: CGSize, expected: Bool) {
        #expect(SideBySideLayout.isWide(size) == expected)
    }
}
