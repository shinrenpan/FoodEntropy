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
