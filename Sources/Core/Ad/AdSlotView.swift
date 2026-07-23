import SwiftUI

// 首頁頂部廣告位（02-architecture §9、01-navigation §2）。
// AdMob 非個人化 banner，右上角標「廣告」明確區隔內容。
// 由呼叫端依 adsRemoved 決定是否放入畫面（未來持有 IAP entitlement 時不放）。
struct AdSlotView: View {
    var body: some View {
        BannerAdView(adUnitID: AdConfig.homeBannerUnitID)
            .frame(maxWidth: .infinity)
            .frame(height: 50)                 // AdSizeBanner 固定高度
            .overlay(alignment: .topTrailing) {
                Text("廣告")
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .foregroundStyle(.secondary)
            }
    }
}
