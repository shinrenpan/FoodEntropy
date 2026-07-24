import SwiftUI

// 首頁頂部廣告位（02-architecture §9、01-navigation §2）。
// AdMob 非個人化 banner，右上角標「廣告」明確區隔內容。
// 版位保留 50pt 讓 banner 能載入；只有「確定無 fill / 載入失敗」才收合為 0，不留空框。
// 由呼叫端依 adsRemoved 決定是否放入畫面（持有 IAP entitlement 時不放）。
struct AdSlotView: View {
    private enum LoadState { case loading, loaded, failed }
    @State private var state: LoadState = .loading

    var body: some View {
        BannerAdView(adUnitID: AdConfig.homeBannerUnitID) { success in
            state = success ? .loaded : .failed
        }
        .frame(maxWidth: .infinity)
        .frame(height: state == .failed ? 0 : 50)   // 載入中/成功 = 50；失敗才收合
        .clipped()
        .overlay(alignment: .topTrailing) {
            if state == .loaded {
                Text("廣告")
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .foregroundStyle(.secondary)
            }
        }
        .animation(.default, value: state)
    }
}
