import Charts
import SwiftUI

struct HomeView: View {
    let viewModel: HomeViewModel

    var body: some View {
        @Bindable var bVM = viewModel

        List {
            StatusChartSection(
                expired: viewModel.state.expired.count,
                nearExpiry: viewModel.state.nearExpiry.count,
                fresh: viewModel.state.fresh.count,
                upcomingExpiryCost: viewModel.state.upcomingExpiryCost
            )

            WasteStatsSection(
                consumed: viewModel.state.consumedCount,
                wasted: viewModel.state.wastedCount,
                wasteRate: viewModel.state.wasteRate,
                hasHistory: viewModel.state.hasHistory,
                wastedCost: viewModel.state.wastedCost,
                onClear: { Task { await viewModel.doAction(.view(.clearHistoryDidTap)) } }
            )

            BucketSection(title: "已過期未處理", items: viewModel.state.expired, send: handleListAction)
            BucketSection(title: "3 天內到期", items: viewModel.state.nearExpiry, send: handleListAction)
            BucketSection(
                title: "保存期限內",
                items: viewModel.state.fresh,
                footer: "提示：點項目可編輯；左右滑可標記已使用 / 刪除；長按可延長效期或標記丟棄。",
                send: handleListAction
            )
        }
        .listStyle(.insetGrouped)
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
        .alert(
            "確定刪除？",
            isPresented: deleteAlertPresented(),
            presenting: viewModel.state.pendingDeleteItem
        ) { _ in
            Button("刪除", role: .destructive) {
                Task { await viewModel.doAction(.view(.deleteConfirmed)) }
            }
            Button("取消", role: .cancel) {
                Task { await viewModel.doAction(.view(.deleteCancelled)) }
            }
        } message: { item in
            Text("「\(item.name)」將被刪除，此操作無法復原。")
        }
        .alert("清除歷史統計？", isPresented: $bVM.state.showClearHistoryConfirm) {
            Button("清除", role: .destructive) {
                Task { await viewModel.doAction(.view(.clearHistoryConfirmed)) }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("將刪除所有「已使用 / 丟棄」紀錄，浪費統計將歸零。此操作無法復原。")
        }
        .sheet(item: extendItemBinding()) { item in
            ExtendSheet(item: item, send: handleExtendAction)
        }
    }

    // MARK: - L1 協調

    private func handleListAction(_ action: BucketSection.Action) {
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

// MARK: - 現況甜甜圈

private extension HomeView {
    struct StatusSlice: Identifiable {
        let status: ExpiryStatus
        let count: Int

        var id: String { status.rawValue }   // 僅供 Identifiable，不面向使用者
        var color: Color { expiryColor(status) }
    }

    struct StatusChartSection: View {
        let expired: Int
        let nearExpiry: Int
        let fresh: Int
        /// nil = 無可計算金額（沒有 nearExpiry 項目帶價格）→ 整行不渲染，不顯示 0。
        var upcomingExpiryCost: Double? = nil

        private var total: Int { expired + nearExpiry + fresh }
        private var slices: [StatusSlice] {
            [
                .init(status: .expired, count: expired),
                .init(status: .nearExpiry, count: nearExpiry),
                .init(status: .fresh, count: fresh),
            ]
        }

        var body: some View {
            Section("現況") {
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

        @ViewBuilder private func donut() -> some View {
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
        @ViewBuilder private func statusLabel(_ status: ExpiryStatus) -> some View {
            switch status {
            case .expired: Text("已過期")
            case .nearExpiry: Text("3 天內到期")
            case .fresh: Text("保存期限內")
            }
        }

        @ViewBuilder private func legend() -> some View {
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
}

// MARK: - 浪費統計

private extension HomeView {
    struct WasteStatsSection: View {
        let consumed: Int
        let wasted: Int
        let wasteRate: Double?
        let hasHistory: Bool
        /// nil = 視窗內沒有已記錄價格的丟棄項 → 該行不渲染。附屬資訊，層級低於浪費率。
        var wastedCost: Double? = nil
        let onClear: () -> Void

        var body: some View {
            Section {
                if let wasteRate {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("浪費率")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            // 百分比交由 FormatStyle 產生：各語言的符號位置與間距不同，
                            // 手動接 "%" 會在部分地區顯示錯誤。.percent 亦自行處理 0.2 → 20%。
                            Text(wasteRate, format: .percent.precision(.fractionLength(0)))
                                .font(.title.bold())
                                .monospacedDigit()
                                .foregroundStyle(wasteRate >= 0.3 ? .red : .primary)
                        }
                        proportionBar()
                        HStack {
                            Label("吃掉 \(consumed)", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Spacer()
                            Label("丟棄 \(wasted)", systemImage: "trash.fill")
                                .foregroundStyle(.red)
                        }
                        .font(.footnote)
                        .monospacedDigit()

                        // 已丟棄金額：刻意作為附屬資訊。若放大成 hero，部分填價格造成的
                        // 低估會讀成「才這樣而已」，比原本只有百分比更沒有壓力。
                        if let wastedCost {
                            Text("其中已記錄價格者共 \(wastedCost.currencyText())")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .accessibilityLabel(Text("其中已記錄價格者共 \(wastedCost.currencyAccessibilityText())"))
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    Text("尚無已處理紀錄")
                        .foregroundStyle(.secondary)
                }
            } header: {
                HStack {
                    Text("浪費統計")
                    Spacer()
                    if hasHistory {
                        Button("清除", role: .destructive, action: onClear)
                            .font(.caption)
                            .textCase(nil)   // 覆寫 section header 的自動大寫
                    }
                }
            } footer: {
                Text("近 30 天內標記「已使用」與「丟棄」的統計。")
            }
        }

        // 綠（吃掉）/ 紅（丟棄）比例條
        @ViewBuilder private func proportionBar() -> some View {
            Chart {
                BarMark(x: .value("吃掉", consumed), y: .value("", "resolved"))
                    .foregroundStyle(.green)
                BarMark(x: .value("丟棄", wasted), y: .value("", "resolved"))
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

// MARK: - 分桶清單（可互動）

private extension HomeView {
    struct BucketSection: View {
        enum Action: Sendable {
            case rowDidTap(FoodItem)
            case consumeDidTap(FoodItem)
            case wasteDidTap(FoodItem)
            case deleteDidTap(FoodItem)
            case extendDidTap(FoodItem)
        }

        let title: LocalizedStringKey
        let items: [FoodItem]
        var footer: LocalizedStringKey? = nil
        let send: (Action) -> Void

        var body: some View {
            Section {
                if items.isEmpty {
                    Text("沒有項目")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(items) { item in
                        row(item)
                    }
                }
            } header: {
                HStack {
                    Text(title)
                    Spacer()
                    Text("\(items.count) 項")
                }
            } footer: {
                if let footer {
                    Text(footer)
                }
            }
        }

        @ViewBuilder private func row(_ item: FoodItem) -> some View {
            FoodRowView(item: item)
                .contentShape(Rectangle())
                .onTapGesture { send(.rowDidTap(item)) }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button { send(.consumeDidTap(item)) } label: {
                        Label("已使用", systemImage: "checkmark")
                    }
                    .tint(.green)
                }
                // 刻意不用 role: .destructive：destructive 會讓 SwiftUI 一點擊就自動移除 row，
                // 但本操作需先跳確認 alert（真正刪除由 deleteConfirmed 觸發 manager.delete + reload）。
                // 改用 .tint(.red) 保留紅色。allowsFullSwipe 維持 true 與 leading 一致。見 issue #1。
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button { send(.deleteDidTap(item)) } label: {
                        Label("刪除", systemImage: "trash")
                    }
                    .tint(.red)
                }
                // 編輯 → 點 row；刪除 → 左滑。長按只放「不在滑動 / 點擊上」的動作。
                .contextMenu {
                    Button { send(.extendDidTap(item)) } label: { Label("延長效期", systemImage: "calendar") }
                    Button { send(.consumeDidTap(item)) } label: { Label("標記已使用", systemImage: "checkmark.circle") }
                    Button { send(.wasteDidTap(item)) } label: { Label("標記丟棄", systemImage: "trash.slash") }
                }
        }
    }

    struct AddButton: View {
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Label("新增食材", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(.tint, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 16)   // 與 tab bar 拉開距離，避免誤觸
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
                        "新的到期日",
                        selection: $newExpiry,
                        in: item.purchaseDate...,
                        displayedComponents: .date
                    )
                }
                .navigationTitle("延長效期")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") { send(.cancelDidTap) }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("儲存") { send(.confirmDidTap(newExpiry)) }
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
        manager.create(
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
