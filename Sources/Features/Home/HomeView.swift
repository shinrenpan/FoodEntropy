import Charts
import SwiftUI
import UIKit

// 首頁是儀表板，不是工作檯（見 home-ui）。
//
// 五張卡一疊：Current／Waste Stats／過期／3 天內／保存期限內。未選中者被下一張
// 壓住只露出頂緣，選中者排在最後完整顯示。食材清單不在這裡——那是分桶清單畫面，
// 由分桶卡的第二次點擊開啟。
struct HomeView: View {
    let viewModel: HomeViewModel

    var body: some View {
        @Bindable var bVM = viewModel

        ScrollView {
            HomeCardStack(
                state: viewModel.state,
                onSelect: { card in
                    Task { await viewModel.doAction(.view(.cardDidTap(card))) }
                },
                onClear: {
                    Task { await viewModel.doAction(.view(.clearHistoryDidTap)) }
                }
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 設定不再是並列的 tab，改為從這裡推入（見 home-ui）。
            // 走 ViewAction → Router → HostController，不在 HostController 直接掛 bar button。
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.doAction(.view(.settingsDidTap)) }
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            // 廣告釘在卡堆之上：AdSlotView 自帶不透明底 + 收合邏輯（無廣告自行消失）。
            if !viewModel.state.adsRemoved {
                AdSlotView()
            }
        }
        .safeAreaInset(edge: .bottom) {
            AddButton {
                Task { await viewModel.doAction(.view(.addDidTap)) }
            }
        }
        .onAppear {
            Task { await viewModel.doAction(.view(.onAppear)) }
        }
        // App Intents 可能在 app 停留背景時改動資料（見 app-intents 決策八）。
        // .onAppear 不會因為回到前景而再次觸發。
        //
        // 用 UIApplication 的通知而非 @Environment(\.scenePhase)：食熵是 UIKit
        // 生命週期（UIHostingController），scenePhase 不會送到這裡。
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task { await viewModel.doAction(.view(.onAppear)) }
        }
        // 前景中被改動時（分桶清單內的處置、或 iOS 27 在前景下拉 Spotlight 執行動作），
        // 沒有生命週期轉換可依附，改聽資料層的變動廣播。這也是清單關閉後首頁
        // 卡片會同步的機制——首頁不需要知道清單何時關閉。
        .onReceive(NotificationCenter.default.publisher(for: SwiftDataManager.didChangeNotification)) { _ in
            Task { await viewModel.doAction(.view(.onAppear)) }
        }
        .alert("Clear history?", isPresented: $bVM.state.showClearHistoryConfirm) {
            Button("Clear", role: .destructive) {
                Task { await viewModel.doAction(.view(.clearHistoryConfirmed)) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all Used / Discarded records; waste stats will reset. This cannot be undone.")
        }
    }
}

// MARK: - 卡片堆疊

private extension HomeView {
    // 未選中的卡以固定高度排列並被下一張壓住，只露出頂緣；選中者排在最後，
    // 因此不被任何卡遮擋（Wallet 的順序，見 home-ui）。
    struct HomeCardStack: View {
        let state: HomeViewModel.State
        let onSelect: (HomeCard) -> Void
        let onClear: () -> Void

        /// 收合卡的整體高度；其中只有 peekHeight 會露出來。
        private static let collapsedHeight: CGFloat = 140
        private static let peekHeight: CGFloat = 74

        private var displayOrder: [HomeCard] {
            HomeCard.allCases.filter { $0 != state.selectedCard } + [state.selectedCard]
        }

        var body: some View {
            VStack(spacing: -(Self.collapsedHeight - Self.peekHeight)) {
                ForEach(displayOrder, id: \.self) { card in
                    HomeCardView(
                        card: card,
                        state: state,
                        isSelected: card == state.selectedCard,
                        collapsedHeight: Self.collapsedHeight,
                        onTap: { onSelect(card) },
                        onClear: onClear
                    )
                }
            }
            .animation(.snappy(duration: 0.3), value: state.selectedCard)
        }
    }

    struct HomeCardView: View {
        let card: HomeCard
        let state: HomeViewModel.State
        let isSelected: Bool
        let collapsedHeight: CGFloat
        let onTap: () -> Void
        let onClear: () -> Void

        /// 展開卡內容區的最小高度。
        ///
        /// 分桶卡以此為固定高度——有金額與沒金額必須一樣高，否則切換分桶時整疊會跳
        /// （見 home-ui）。摘要卡以此為下限：資料為空時它們的內容只有一行空狀態訊息，
        /// 沒有下限就會塌成一條，與同樣空著的分桶卡高度不一致。
        private static let selectedContentHeight: CGFloat = 78

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                header()
                if isSelected {
                    content()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: isSelected ? nil : collapsedHeight, alignment: .top)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(gradient)
                    .shadow(color: .black.opacity(0.22), radius: isSelected ? 12 : 6, y: 4)
            }
            // 開啟提示屬於整張卡，不是標題列裡那個數字的附屬品——整張卡都可點，
            // 所以比照 iOS 的 disclosure indicator 貼在卡片右緣垂直置中。
            // 只在「已在最前面且有內容的分桶卡」出現，不對摘要卡與空桶誤導（見 home-ui）。
            .overlay(alignment: .trailing) {
                if showsOpenHint {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.trailing, 18)
                }
            }
        }

        // 露出的頂緣：全部資訊放同一行。跨行的內容會被下一張切成一半。
        @ViewBuilder private func header() -> some View {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 8)
                if let headline {
                    Text(headline)
                        .font(.subheadline)
                        .monospacedDigit()
                        .opacity(0.9)
                }
                if let count {
                    Text("\(count)")
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
        }

        @ViewBuilder private func content() -> some View {
            switch card {
            // 摘要卡的內容包在淺色面板裡：圓形圖與統計是深色前景，
            // 直接畫在飽和色卡面上會失去可讀性（見 home-ui）。
            case .current:
                panel {
                    StatusChartView(
                        expired: state.expired.count,
                        nearExpiry: state.nearExpiry.count,
                        fresh: state.fresh.count,
                        upcomingExpiryCost: state.upcomingExpiryCost
                    )
                }
            case .waste:
                panel {
                    WastePanel(
                        consumed: state.consumedCount,
                        wasted: state.wastedCount,
                        wasteRate: state.wasteRate,
                        hasHistory: state.hasHistory,
                        wastedCost: state.wastedCost,
                        onClear: onClear
                    )
                }
            // 分桶卡只有數字與短句，白字直接寫在卡面上，不需再包一層。
            case .expired, .nearExpiry, .fresh:
                bucketContent()
            }
        }

        @ViewBuilder private func panel<Content: View>(@ViewBuilder _ inner: () -> Content) -> some View {
            inner()
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: Self.selectedContentHeight, alignment: .topLeading)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
        }

        // 卡面永遠是兩個真實事實：金額（損失多少）與時間（多久壞）。
        // 沒有已記錄價格時時間升為主要資訊——不補 0、不提示去記錄價格
        // （見 home-ui 的「金額為零時整行消失」）。
        @ViewBuilder private func bucketContent() -> some View {
            VStack(alignment: .leading, spacing: 2) {
                if bucketItems.isEmpty {
                    Text("No items")
                        .font(.subheadline)
                        .opacity(0.85)
                } else if let cost = bucketCost {
                    Text(cost.currencyText())
                        .font(.system(size: 36, weight: .bold))
                        .monospacedDigit()
                    if let soonestText {
                        Text(soonestText)
                            .font(.footnote)
                            .opacity(0.85)
                    }
                } else if let soonestText {
                    Text(soonestText)
                        .font(.title2.weight(.semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: Self.selectedContentHeight, alignment: .topLeading)
            .padding(.horizontal, 18)
            .padding(.bottom, 20)
            // 展開後的下半部也是卡片的一部分——「Tapping a card」指整張卡，
            // 不是只有標題列（見 home-ui）。摘要卡不需要：它們不開清單。
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
        }

        private var showsOpenHint: Bool {
            isSelected && card.bucket != nil && !bucketItems.isEmpty
        }

        private var bucketItems: [FoodItem] {
            card.bucket.map { state.items(in: $0) } ?? []
        }

        private var bucketCost: Double? {
            card.bucket.flatMap { state.cost(in: $0) }
        }

        /// 該桶第一筆的到期描述。清單依到期日升冪（見 persistence 的查詢排序契約），
        /// 所以未過期的桶取到「最快到期」，已過期的桶取到「過期最久」。
        /// 沿用食材列既有的字串，不新增翻譯。
        private var soonestText: LocalizedStringKey? {
            guard let item = bucketItems.first else { return nil }
            let days = item.daysUntilExpiry()
            if days < 0 { return "Expired \(-days) days ago" }
            if days == 0 { return "Expires today" }
            return "\(days) days left"
        }

        private var gradient: LinearGradient {
            let base: Color = switch card {
            case .current: .blue
            case .waste: .indigo
            case .expired: expiryColor(.expired)
            case .nearExpiry: expiryColor(.nearExpiry)
            case .fresh: expiryColor(.fresh)
            }
            // 必須完全不透明：卡片互相疊壓，半透明會讓下層的文字透出來。
            return LinearGradient(
                colors: [base, base.mix(with: .black, by: 0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        private var title: LocalizedStringKey {
            switch card {
            case .current: "Current"
            case .waste: "Waste Stats"
            case .expired: "Expired, unhandled"
            case .nearExpiry: "Expiring within 3 days"
            case .fresh: "Fresh"
            }
        }

        private var count: Int? {
            switch card {
            case .current: state.activeTotal
            case .waste: nil
            case .expired, .nearExpiry, .fresh: bucketItems.count
            }
        }

        /// 頂緣右側的附加數字。分桶的金額放在卡片內容裡（大字），不在這裡重複。
        ///
        /// 浪費率無資料時顯示破折號而非 0%：0% 讀起來是「一點都沒浪費」這項成績，
        /// 而真相是還沒有任何已處理紀錄、無從計算（見 home-ui：不得以零百分比取代
        /// 空狀態）。但也不能留空——其餘四張卡右側都有數字，留空會像漏渲染。
        private var headline: String? {
            switch card {
            case .waste:
                state.wasteRate.map { $0.formatted(.percent.precision(.fractionLength(0))) } ?? "—"
            case .current, .expired, .nearExpiry, .fresh:
                nil
            }
        }
    }

    struct WastePanel: View {
        let consumed: Int
        let wasted: Int
        let wasteRate: Double?
        let hasHistory: Bool
        /// nil = 視窗內沒有已記錄價格的丟棄項 → 該行不渲染。附屬資訊，層級低於浪費率。
        let wastedCost: Double?
        let onClear: () -> Void

        var body: some View {
            if let wasteRate {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Waste rate")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if hasHistory {
                            Button("Clear", role: .destructive, action: onClear)
                                .font(.caption)
                        }
                    }
                    // 百分比交由 FormatStyle 產生：各語言的符號位置與間距不同，
                    // 手動接 "%" 會在部分地區顯示錯誤。
                    Text(wasteRate, format: .percent.precision(.fractionLength(0)))
                        .font(.system(size: 40, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(wasteRate >= 0.3 ? .red : .primary)
                    proportionBar()
                    HStack {
                        Label("Used \(consumed)", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Spacer()
                        Label("Discarded \(wasted)", systemImage: "trash.fill")
                            .foregroundStyle(.red)
                    }
                    .font(.footnote)
                    .monospacedDigit()

                    // 已丟棄金額：刻意作為附屬資訊。若放大成 hero，部分填價格造成的
                    // 低估會讀成「才這樣而已」，比原本只有百分比更沒有壓力。
                    if let wastedCost {
                        Text("Recorded prices total \(wastedCost.currencyText())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // 統計視窗的說明。少了它，畫面上的百分比沒有任何時間範圍線索。
                    Text("Stats for items marked Used / Discarded in the last 30 days.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            } else {
                Text("No records yet")
                    .foregroundStyle(.secondary)
            }
        }


        // 綠（吃掉）/ 紅（丟棄）比例條
        @ViewBuilder private func proportionBar() -> some View {
            Chart {
                BarMark(x: .value("Used", consumed), y: .value("", "resolved"))
                    .foregroundStyle(.green)
                BarMark(x: .value("Discarded", wasted), y: .value("", "resolved"))
                    .foregroundStyle(.red)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .frame(height: 14)
            // 對 VoiceOver 隱藏：Chart 自帶 accessibility tree 與聲波圖，會唸出
            // 「y 軸為 resolved、2 個資料點」這類內部細節；而它呈現的資訊已由下方
            // 「吃掉 N／丟棄 N」的文字完整提供，重複朗讀只是干擾。
            .accessibilityHidden(true)
        }
    }
}

// MARK: - 新增按鈕

private extension HomeView {
    struct AddButton: View {
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Label("Add Food", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(.tint, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 16)   // 疊在 home indicator 安全區之上的呼吸空間（共約 50pt）
            .background(.bar)
        }
    }
}
