import GoogleMobileAds
import SwiftUI
import UIKit

// 把 AdMob 的 UIKit `BannerView` 橋接進 SwiftUI（固定 320x50 標準 banner）。
// 載入非個人化請求；rootViewController 從當前 key window 取得。
struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)   // 320x50，高度固定好排版
        banner.adUnitID = adUnitID
        banner.rootViewController = Self.keyRootViewController()
        banner.load(AdConfig.makeRequest())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    /// 取當前 key window 的 rootViewController（BannerView 呈現全螢幕點擊需要）。
    private static func keyRootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
