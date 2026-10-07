import CoreGraphics
import Testing
@testable import FoodEntropy

/// 廣告的寬度由版面決定（見 advertising〈The banner takes its width from the layout,
/// not from the ad SDK〉）。期望值來自 AdMob 標準 banner 的固定規格 320×50。
struct BannerAdViewTests {

    @Test("提案寬度直接作為廣告寬度，高度固定 50")
    func usesProposedWidth() {
        #expect(BannerAdView.layoutSize(proposedWidth: 391) == CGSize(width: 391, height: 50))
        #expect(BannerAdView.layoutSize(proposedWidth: 637) == CGSize(width: 637, height: 50))
    }

    @Test("沒有提案寬度時退回標準寬度 320")
    func fallsBackWhenUnspecified() {
        #expect(BannerAdView.layoutSize(proposedWidth: nil) == CGSize(width: 320, height: 50))
    }

    /// 外層以無限大提案量測時（例如水平捲動、ProposedViewSize.infinity），
    /// 回傳無限寬會讓版面失效，所以視同沒有提案。
    @Test("提案寬度無限大時退回標準寬度 320")
    func fallsBackWhenInfinite() {
        #expect(BannerAdView.layoutSize(proposedWidth: .infinity) == CGSize(width: 320, height: 50))
    }
}
