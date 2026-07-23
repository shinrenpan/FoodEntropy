import SwiftUI

// 跨 feature 共用的食材列（首頁 + 分析）。純展示，無互動；
// 互動（滑動 / 長按 / 點擊）由使用它的 feature 於外層包上。
struct FoodRowView: View {
    let item: FoodItem

    var body: some View {
        let status = item.expiryStatus()
        let days = item.daysUntilExpiry()
        HStack(spacing: 12) {
            thumbnail()
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body)
                expiryText(days: days)
                    .font(.subheadline)
                    .foregroundStyle(expiryColor(status))
            }
            Spacer(minLength: 0)
            Circle()
                .fill(expiryColor(status))
                .frame(width: 10, height: 10)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder private func thumbnail() -> some View {
        if let data = item.imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
        }
    }

    private func expiryText(days: Int) -> Text {
        if days < 0 {
            Text("已過期 \(-days) 天")
        } else if days == 0 {
            Text("今天到期")
        } else {
            Text("還有 \(days) 天")
        }
    }
}

// V 層顏色對映（Domain 不回傳 UI 型別）。紅綠燈語意：綠=期限內 / 橙=快到 / 紅=過期。
func expiryColor(_ status: ExpiryStatus) -> Color {
    switch status {
    case .fresh: .green
    case .nearExpiry: .orange
    case .expired: .red
    }
}
