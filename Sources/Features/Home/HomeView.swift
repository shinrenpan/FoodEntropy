import AppIntents
import Charts
import SwiftUI
import UIKit

struct HomeView: View {
    let viewModel: HomeViewModel


    var body: some View {
        @Bindable var bVM = viewModel

        ScrollView {
            // SPIKE v7：五張卡一疊。Current／Waste 是摘要，點了只移到前面；
            // 三張分桶卡點了會開 sheet（sheet 裡是真正的 List，四個手勢都在）。
            HomeCardStack(
                state: viewModel.state,
                onSelect: { card in
                    Task { await viewModel.doAction(.view(.cardDidTap(card))) }
                },
                onClear: { Task { await viewModel.doAction(.view(.clearHistoryDidTap)) } }
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(
            isPresented: Binding(
                get: { viewModel.state.sheetBucket != nil },
                set: { if !$0 { Task { await viewModel.doAction(.view(.bucketSheetDismissed)) } } }
            )
        ) {
            if let bucket = viewModel.state.sheetBucket {
                BucketListSheet(
                    bucket: bucket,
                    items: viewModel.state.items(in: bucket),
                    send: handleListAction,
                    onDone: { Task { await viewModel.doAction(.view(.bucketSheetDismissed)) } }
                )
            }
        }
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
            // 廣告釘在清單頂：AdSlotView 自帶不透明底 + 收合邏輯（無廣告自行消失）。
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
        // .onAppear 不會因為回到前景而再次觸發，少了這條首頁會顯示已處理的食材。
        //
        // 用 UIApplication 的通知而非 @Environment(\.scenePhase)：食熵是 UIKit
        // 生命週期（UIHostingController），scenePhase 不會送到這裡——2026-09-11
        // 實機實測，捷徑在背景標記已使用後切回前景，清單沒更新，滑掉重開才正確。
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // 沿用既有的 onAppear ViewAction，不新增 Action case（維持單向資料流）。
            Task { await viewModel.doAction(.view(.onAppear)) }
        }
        // 前景中被改動時（iOS 27 可在 app 前景下拉 Spotlight 執行動作），
        // 沒有生命週期轉換可依附，改聽資料層的變動廣播。
        .onReceive(NotificationCenter.default.publisher(for: SwiftDataManager.didChangeNotification)) { _ in
            Task { await viewModel.doAction(.view(.onAppear)) }
        }
        .alert(
            "Delete this item?",
            isPresented: deleteAlertPresented(),
            presenting: viewModel.state.pendingDeleteItem
        ) { _ in
            Button("Delete", role: .destructive) {
                Task { await viewModel.doAction(.view(.deleteConfirmed)) }
            }
            Button("Cancel", role: .cancel) {
                Task { await viewModel.doAction(.view(.deleteCancelled)) }
            }
        } message: { item in
            Text("“\(item.name)” will be deleted. This cannot be undone.")
        }
        .alert("Clear history?", isPresented: $bVM.state.showClearHistoryConfirm) {
            Button("Clear", role: .destructive) {
                Task { await viewModel.doAction(.view(.clearHistoryConfirmed)) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all Used / Discarded records; waste stats will reset. This cannot be undone.")
        }
        .sheet(item: extendItemBinding()) { item in
            ExtendSheet(item: item, send: handleExtendAction)
        }
    }

    static let bucketOrder: [ExpiryStatus] = [.expired, .nearExpiry, .fresh]

    private func bucketCost(_ bucket: ExpiryStatus) -> Double? {
        switch bucket {
        case .expired: viewModel.state.expiredCost
        case .nearExpiry: viewModel.state.upcomingExpiryCost
        case .fresh: nil
        }
    }

    private func bucketTitle(_ bucket: ExpiryStatus) -> LocalizedStringKey {
        switch bucket {
        case .expired: "Expired, unhandled"
        case .nearExpiry: "Expiring within 3 days"
        case .fresh: "Fresh"
        }
    }

    // MARK: - L1 協調

    private func handleListAction(_ action: BucketCard.Action) {
        switch action {
        case let .rowDidTap(item):
            Task { await viewModel.doAction(.view(.rowDidTap(item))) }
        case let .consumeDidTap(item):
            Task { await viewModel.doAction(.view(.consumeDidTap(item))) }
        case let .wasteDidTap(item):
            Task { await viewModel.doAction(.view(.wasteDidTap(item))) }
        case let .deleteDidTap(item):
            Task { await viewModel.doAction(.view(.deleteDidTap(item))) }
        case let .extendDidTap(item):
            Task { await viewModel.doAction(.view(.extendDidTap(item))) }
        }
    }

    private func handleExtendAction(_ action: ExtendSheet.Action) {
        switch action {
        case let .confirmDidTap(date):
            Task { await viewModel.doAction(.view(.extendCommitted(date))) }
        case .cancelDidTap:
            Task { await viewModel.doAction(.view(.extendCancelled)) }
        }
    }

    // 刪除確認以 pendingDeleteItem 驅動；關閉一律回 doAction，不直接改 state。
    private func deleteAlertPresented() -> Binding<Bool> {
        Binding(
            get: { viewModel.state.pendingDeleteItem != nil },
            set: { isPresented in
                if !isPresented {
                    Task { await viewModel.doAction(.view(.deleteCancelled)) }
                }
            }
        )
    }

    private func extendItemBinding() -> Binding<FoodItem?> {
        Binding(
            get: { viewModel.state.extendingItem },
            set: { newValue in
                if newValue == nil {
                    Task { await viewModel.doAction(.view(.extendCancelled)) }
                }
            }
        )
    }
}

// MARK: - 浪費統計

private extension HomeView {
    struct WastePanel: View {
        let consumed: Int
        let wasted: Int
        let wasteRate: Double?
        let hasHistory: Bool
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
                    // 百分比交由 FormatStyle 產生：各語言的符號位置與間距不同。
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

                    // 已丟棄金額刻意作為附屬資訊，不放大成 hero。
                    if let wastedCost {
                        Text("Recorded prices total \(wastedCost.currencyText())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("No records yet")
                    .foregroundStyle(.secondary)
            }
        }

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
            .accessibilityHidden(true)
        }
    }

    // SPIKE v7：五張卡一疊（Current／Waste／過期／3 天內／保存期限內）。
    //
    // 每張卡都是「有色頂緣 + 白色內容區」：頂緣是 peek 時唯一看得到的部分，
    // 白色內容區讓圓形圖與食材列維持原本的可讀性（有色底上放圖表會糊掉）。
    //
    // 選中者排在最後完整顯示（Wallet 的順序）。分桶卡被點時另外開 sheet，
    // 因此它在前景時只需放簡易資訊，不必長——整疊的高度由兩張摘要卡決定。
    struct HomeCardStack: View {
        let state: HomeViewModel.State
        let onSelect: (HomeCard) -> Void
        let onClear: () -> Void

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
        }

        // 露出的頂緣：全部資訊放同一行，跨行會被下一張切成一半。
        @ViewBuilder private func header() -> some View {
            Button(action: onTap) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Spacer(minLength: 8)
                    if let trailing {
                        Text(trailing)
                            .font(.subheadline)
                            .monospacedDigit()
                            .opacity(0.9)
                    }
                    if let count {
                        Text("\(count)")
                            .font(.title3.weight(.bold))
                            .monospacedDigit()
                    }
                    // 只有「已在最前面、且有內容的分桶卡」才會再點開清單，
                    // 提示也只在那個狀態出現，不誤導其他卡。
                    if showsOpenHint {
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.bold))
                            .opacity(0.8)
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }

        @ViewBuilder private func content() -> some View {
            switch card {
            // 摘要卡需要白色面板：圓形圖與統計是深色內容，畫在有色卡面上會糊掉。
            case .current:
                StatusChartView(
                    expired: state.expired.count,
                    nearExpiry: state.nearExpiry.count,
                    fresh: state.fresh.count,
                    upcomingExpiryCost: state.upcomingExpiryCost
                )
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            case .waste:
                WastePanel(
                    consumed: state.consumedCount,
                    wasted: state.wastedCount,
                    wasteRate: state.wasteRate,
                    hasHistory: state.hasHistory,
                    wastedCost: state.wastedCost,
                    onClear: onClear
                )
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            // 分桶卡只有金額與一句說明，白字直接寫在卡面上——不需要再包一層膠囊。
            case .expired, .nearExpiry, .fresh:
                bucketPreview()
            }
        }

        // 分桶卡的簡易資訊：點卡片一定會開 sheet，所以這裡刻意**不**預覽食材——
        // 使用者剛關掉的就是那份清單，再列兩筆只是重複。卡片給的是清單不會給的：
        // 這一桶還有多少錢在裡面。
        // 卡片內容永遠是兩件不同的事實，沒有湊字數的固定文案：
        // 金額＝損失多少，天數＝多久壞。沒有已記錄價格時，天數自動升為主角。
        // 不補 0、不提示去填價格——見 home-ui 的「金額為零時整行消失」。
        @ViewBuilder private func bucketPreview() -> some View {
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
            // 固定高度：有金額與沒金額的卡必須一樣高，否則切換分桶時整疊會跳。
            .frame(maxWidth: .infinity, minHeight: Self.bucketContentHeight, alignment: .topLeading)
            .padding(.horizontal, 18)
            .padding(.bottom, 20)
        }

        private var showsOpenHint: Bool {
            isSelected && card.bucket != nil && !bucketItems.isEmpty
        }

        private var bucketItems: [FoodItem] {
            card.bucket.map { state.items(in: $0) } ?? []
        }

        /// 這一桶的第一筆——清單依到期日升冪，所以是「最快到期」，
        /// 而在已過期桶裡即「過期最久」的那筆。沿用食材列既有的字串，不新增翻譯。
        private var soonestText: LocalizedStringKey? {
            guard let item = bucketItems.first else { return nil }
            let days = item.daysUntilExpiry()
            if days < 0 { return "Expired \(-days) days ago" }
            if days == 0 { return "Expires today" }
            return "\(days) days left"
        }

        /// 分桶卡內容區的固定高度（金額 + 說明的空間）。
        private static let bucketContentHeight: CGFloat = 78

        private var bucketCost: Double? {
            switch card {
            case .expired: state.expiredCost
            case .nearExpiry: state.upcomingExpiryCost
            case .current, .waste, .fresh: nil
            }
        }

        private var gradient: LinearGradient {
            let base: Color = switch card {
            case .current: .blue
            case .waste: .indigo
            case .expired: expiryColor(.expired)
            case .nearExpiry: expiryColor(.nearExpiry)
            case .fresh: expiryColor(.fresh)
            }
            // 完全不透明：卡片互相疊壓，半透明會讓下層文字透出來。
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
            case .expired: state.expired.count
            case .nearExpiry: state.nearExpiry.count
            case .fresh: state.fresh.count
            }
        }

        private var trailing: String? {
            switch card {
            case .current: nil
            case .waste: state.wasteRate.map { $0.formatted(.percent.precision(.fractionLength(0))) }
            // 分桶的金額放在卡片內容（大字），不放 peek——同一個數字不必出現兩次。
            case .expired, .nearExpiry, .fresh: nil
            }
        }
    }

    // 分桶的完整清單。這裡是真正的 List，所以四個手勢完全不用重寫。
    struct BucketListSheet: View {
        let bucket: ExpiryStatus
        let items: [FoodItem]
        let send: (BucketCard.Action) -> Void
        let onDone: () -> Void

        var body: some View {
            NavigationStack {
                List {
                    ForEach(items) { item in
                        FoodRowView(item: item)
                            .appEntityIdentifier(EntityIdentifier(for: FoodItemAppEntity.self, identifier: item.id))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onDone()
                                send(.rowDidTap(item))
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button { send(.consumeDidTap(item)) } label: {
                                    Label("Mark as used", systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button { send(.deleteDidTap(item)) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                            .contextMenu {
                                Button { send(.extendDidTap(item)) } label: { Label("Extend expiry", systemImage: "calendar") }
                                Button { send(.consumeDidTap(item)) } label: { Label("Mark as Used", systemImage: "checkmark.circle") }
                                Button { send(.wasteDidTap(item)) } label: { Label("Mark as Discarded", systemImage: "trash.slash") }
                            }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", action: onDone)
                    }
                }
            }
        }

        private var title: LocalizedStringKey {
            switch bucket {
            case .expired: "Expired, unhandled"
            case .nearExpiry: "Expiring within 3 days"
            case .fresh: "Fresh"
            }
        }
    }

    // BucketCard 僅保留 Action 型別，供 sheet 與 HostController 路由共用。
    enum BucketCard {
        enum Action: Sendable {
            case rowDidTap(FoodItem)
            case consumeDidTap(FoodItem)
            case wasteDidTap(FoodItem)
            case deleteDidTap(FoodItem)
            case extendDidTap(FoodItem)
        }
    }

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

    struct ExtendSheet: View {
        enum Action: Sendable {
            case confirmDidTap(Date)
            case cancelDidTap
        }

        let item: FoodItem
        let send: (Action) -> Void

        @State private var newExpiry: Date

        init(item: FoodItem, send: @escaping (Action) -> Void) {
            self.item = item
            self.send = send
            _newExpiry = State(initialValue: item.expiryDate)
        }

        var body: some View {
            NavigationStack {
                Form {
                    DatePicker(
                        "New expiry date",
                        selection: $newExpiry,
                        in: item.purchaseDate...,
                        displayedComponents: .date
                    )
                }
                .navigationTitle("Extend expiry")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { send(.cancelDidTap) }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { send(.confirmDidTap(newExpiry)) }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("有資料") {
    let manager = try! SwiftDataManager(inMemory: true)
    for mock in FoodItem.mocks {
        _ = try? manager.create(
            name: mock.name,
            purchaseDate: mock.purchaseDate,
            expiryDate: mock.expiryDate,
            imageData: mock.imageData
        )
    }
    return HomeView(viewModel: HomeViewModel(manager: manager, store: StoreManager()))
}

#Preview("空狀態") {
    HomeView(viewModel: HomeViewModel(manager: try! SwiftDataManager(inMemory: true), store: StoreManager()))
}
#endif
