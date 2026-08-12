import Charts
import SwiftUI

struct HomeView: View {
    let viewModel: HomeViewModel

    var body: some View {
        @Bindable var bVM = viewModel

        List {
            // 內容由 Core/Components 的共用元件負責，Widget 引用同一份；
            // Section 容器與標題留在這裡——Widget 沒有 List 語境。
            Section("Current") {
                StatusChartView(
                    expired: viewModel.state.expired.count,
                    nearExpiry: viewModel.state.nearExpiry.count,
                    fresh: viewModel.state.fresh.count,
                    upcomingExpiryCost: viewModel.state.upcomingExpiryCost
                )
            }

            WasteStatsSection(
                consumed: viewModel.state.consumedCount,
                wasted: viewModel.state.wastedCount,
                wasteRate: viewModel.state.wasteRate,
                hasHistory: viewModel.state.hasHistory,
                wastedCost: viewModel.state.wastedCost,
                onClear: { Task { await viewModel.doAction(.view(.clearHistoryDidTap)) } }
            )

            BucketSection(title: "Expired, unhandled", items: viewModel.state.expired, send: handleListAction)
            BucketSection(title: "Expiring within 3 days", items: viewModel.state.nearExpiry, send: handleListAction)
            BucketSection(
                title: "Fresh",
                items: viewModel.state.fresh,
                footer: "Tap to edit; swipe to mark used / delete; long-press to extend or discard.",
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
                            Text("Waste rate")
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
                                .accessibilityLabel(Text("Recorded prices total \(wastedCost.currencyAccessibilityText())"))
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    Text("No records yet")
                        .foregroundStyle(.secondary)
                }
            } header: {
                HStack {
                    Text("Waste Stats")
                    Spacer()
                    if hasHistory {
                        Button("Clear", role: .destructive, action: onClear)
                            .font(.caption)
                            .textCase(nil)   // 覆寫 section header 的自動大寫
                    }
                }
            } footer: {
                Text("Stats for items marked Used / Discarded in the last 30 days.")
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
                    Text("No items")
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
                    Text("\(items.count) items")
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
                        Label("Mark as used", systemImage: "checkmark")
                    }
                    .tint(.green)
                }
                // 刻意不用 role: .destructive：destructive 會讓 SwiftUI 一點擊就自動移除 row，
                // 但本操作需先跳確認 alert（真正刪除由 deleteConfirmed 觸發 manager.delete + reload）。
                // 改用 .tint(.red) 保留紅色。allowsFullSwipe 維持 true 與 leading 一致。見 issue #1。
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button { send(.deleteDidTap(item)) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                }
                // 編輯 → 點 row；刪除 → 左滑。長按只放「不在滑動 / 點擊上」的動作。
                .contextMenu {
                    Button { send(.extendDidTap(item)) } label: { Label("Extend expiry", systemImage: "calendar") }
                    Button { send(.consumeDidTap(item)) } label: { Label("Mark as Used", systemImage: "checkmark.circle") }
                    Button { send(.wasteDidTap(item)) } label: { Label("Mark as Discarded", systemImage: "trash.slash") }
                }
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
