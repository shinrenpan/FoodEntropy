import GoogleMobileAds
import SwiftUI
import UIKit

// 把 AdMob 的 UIKit `BannerView` 橋接進 SwiftUI（固定 320x50 標準 banner）。
// 載入非個人化請求；rootViewController 從當前 key window 取得。
// 透過 delegate 回報載入結果，供呼叫端在「無廣告」時收合版位。
struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    var onLoaded: (Bool) -> Void = { _ in }

    func makeCoordinator() -> Coordinator {
        Coordinator(onLoaded: onLoaded)
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)   // 320x50，高度固定好排版
        banner.adUnitID = adUnitID
        banner.rootViewController = Self.keyRootViewController()
        banner.delegate = context.coordinator
        banner.load(AdConfig.makeRequest())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    // 尺寸只看外層提案，不採用 BannerView 自報的 intrinsic size（見 advertising）。
    // BannerView 會把自報寬度撐到上一次被排到的寬度、之後不縮回：app 執行中由寬
    // 變窄（iPhone Duo 單欄轉兩欄）時，沒有這個實作就會溢出、蓋到鄰欄。
    // GoogleMobileAds 13.7.0 與 13.11.0 皆實測重現；與用哪種容器排版無關。
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: BannerView, context: Context) -> CGSize? {
        Self.layoutSize(proposedWidth: proposal.width)
    }

    /// 標準 banner（`AdSizeBanner`）是固定 320×50，所以高度可以寫死。
    /// 若改用 adaptive banner，高度要改用 SDK 的尺寸函式依寬度計算。
    /// 沒有提案或提案無限大時退回標準寬度——回傳無限寬會讓外層版面失效。
    static func layoutSize(proposedWidth: CGFloat?) -> CGSize {
        let standard = AdSizeBanner.size
        guard let width = proposedWidth, width.isFinite else { return standard }
        return CGSize(width: width, height: standard.height)
    }

    /// 取當前 key window 的 rootViewController（BannerView 呈現全螢幕點擊需要）。
    private static func keyRootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }

    @MainActor
    final class Coordinator: NSObject, BannerViewDelegate {
        private let onLoaded: (Bool) -> Void

        init(onLoaded: @escaping (Bool) -> Void) {
            self.onLoaded = onLoaded
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            onLoaded(true)
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: any Error) {
            onLoaded(false)   // 無 fill / 失敗 → 收合版位
        }
    }
}
