import SwiftUI

// 首頁頂部廣告位（02-architecture §9、01-navigation §2）。
// AdMob 非個人化 banner，右上角標「廣告」明確區隔內容。
// 有廣告載入才展開；無 fill（如 AdMob 審核前 / 無填充）時收合為 0 高度，不留空框。
// 由呼叫端依 adsRemoved 決定是否放入畫面（持有 IAP entitlement 時不放）。
struct AdSlotView: View {
    @State private var loaded = false

    var body: some View {
        BannerAdView(adUnitID: AdConfig.homeBannerUnitID) { loaded = $0 }
            .frame(maxWidth: .infinity)
            .frame(height: loaded ? 50 : 0)     // AdSizeBanner 固定高度；無廣告收合
            .clipped()
            .overlay(alignment: .topTrailing) {
                if loaded {
                    Text("廣告")
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .foregroundStyle(.secondary)
                }
            }
            .animation(.default, value: loaded)
    }
}
