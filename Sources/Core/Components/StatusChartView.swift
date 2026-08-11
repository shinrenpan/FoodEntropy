import Charts
import SwiftUI

// 效期現況的共用呈現（首頁「現況」區塊 + Widget）。純展示，不讀資料——
// 呼叫端算好三桶數量與前瞻金額再傳進來，兩處才可能顯示相同結果。
//
// 不含 Section 容器與標題：Widget 沒有 List 語境，Section 在那裡不會渲染成預期樣貌，
// 因此容器留給使用它的畫面自行包上。
struct StatusChartView: View {
    let expired: Int
    let nearExpiry: Int
    let fresh: Int
    /// nil = 無可計算金額（沒有 nearExpiry 項目帶價格）→ 整行不渲染，不顯示 0。
    var upcomingExpiryCost: Double? = nil

    var total: Int { expired + nearExpiry + fresh }

    var slices: [StatusSlice] {
        [
            .init(status: .expired, count: expired),
            .init(status: .nearExpiry, count: nearExpiry),
            .init(status: .fresh, count: fresh),
        ]
    }

    var body: some View {
        if total == 0 {
            Text("目前沒有食材")
                .foregroundStyle(.secondary)
        } else {
            HStack(spacing: 24) {
                donut()
                legend()
            }
            .padding(.vertical, 8)

            // 前瞻金額：食材還救得回來時才說話。固定「至少」語氣——涵蓋率會隨
            // 未填價格的項目浮動，若文案在「NT$X」與「至少 NT$X」間跳動，反而
            // 像在隱瞞什麼。金額格式化交由系統依 locale 處理。
            if let cost = upcomingExpiryCost {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(expiryColor(.nearExpiry))
                        .accessibilityHidden(true)   // 純裝飾，否則唸成「錯誤影像」
                    Text("至少 \(cost.currencyText()) 即將到期")
                        .font(.subheadline)
                        // 視覺用符號（$99），朗讀用完整幣別（99元）——
                        // VoiceOver 會把 $ 唸成「美金」，對非美元地區是錯的。
                        .accessibilityLabel(Text("至少 \(cost.currencyAccessibilityText()) 即將到期"))
                }
            }
        }
    }
}

// MARK: - 切片

extension StatusChartView {
    struct StatusSlice: Identifiable {
        let status: ExpiryStatus
        let count: Int

        var id: String { status.rawValue }   // 僅供 Identifiable，不面向使用者
        var color: Color { expiryColor(status) }
    }
}

// MARK: - 繪製

private extension StatusChartView {
    @ViewBuilder func donut() -> some View {
        Chart(slices) { slice in
            SectorMark(
                angle: .value("數量", slice.count),
                innerRadius: .ratio(0.62),
                angularInset: 2
            )
            .cornerRadius(4)
            .foregroundStyle(slice.color)
        }
        .chartLegend(.hidden)
        // 對 VoiceOver 隱藏：會逐一唸出資料點（「1, 3, 1」），而這些數字右側
        // legend 已完整提供（色點 + 桶名 + 數量）。中心的總數不在 legend 內，
        // 因此保留於下方 overlay。
        .accessibilityHidden(true)
        .frame(width: 120, height: 120)
        .overlay {
            // 圓圈是固定尺寸，極大字級會撐出去——改為縮放而非截斷，
            // 使用者仍讀得到數字（憲章品質基準：Dynamic Type 不破版）。
            VStack(spacing: 0) {
                Text("\(total)")
                    .font(.title2.bold())
                Text("項")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .padding(.horizontal, 8)
            // 數字與單位分屬兩個 Text：.combine 會在兩者間插入停頓（唸成「5、項」），
            // 改以明確 label 唸作「5 項」。此字串與桶 header 共用既有的 catalog key。
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(total) 項"))
        }
    }

    /// 字面值必須直接寫在 `Text()` 內，編譯器才會抽成確定的 key。
    /// 若改成把 `LocalizedStringKey` 當參數傳遞，會被歸入 __PotentialKeys、
    /// 進而在 String Catalog 中被標為 stale——照 warning 清理就會誤刪掉活的翻譯。
    @ViewBuilder func statusLabel(_ status: ExpiryStatus) -> some View {
        switch status {
        case .expired: Text("已過期")
        case .nearExpiry: Text("3 天內到期")
        case .fresh: Text("保存期限內")
        }
    }

    @ViewBuilder func legend() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(slices) { slice in
                HStack(spacing: 8) {
                    Circle()
                        .fill(slice.color)
                        .frame(width: 10, height: 10)
                    statusLabel(slice.status)
                        .font(.subheadline)
                    Spacer(minLength: 12)
                    Text("\(slice.count)")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                }
            }
        }
    }
}
