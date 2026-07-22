import SwiftUI

// 廣告佔位 seam（02-architecture §9）。
// v1：DEBUG 顯示佔位框、Release collapse。Phase 9 換成 AdMob banner，首頁不需改動。
// 由呼叫端依 adsRemoved 決定是否放入畫面（持有 IAP entitlement 時不放）。
struct AdSlotView: View {
    var body: some View {
        #if DEBUG
        RoundedRectangle(cornerRadius: 8)
            .fill(.quaternary)
            .frame(height: 60)
            .overlay {
                Text("Ad Placeholder")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .overlay(alignment: .topTrailing) {
                Text("廣告")
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .foregroundStyle(.secondary)
            }
        #else
        EmptyView()
        #endif
    }
}

#if DEBUG
#Preview {
    AdSlotView()
        .padding()
}
#endif
