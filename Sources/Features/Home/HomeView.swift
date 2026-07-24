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
                fresh: viewModel.state.fresh.count
            )

            WasteStatsSection(
                consumed: viewModel.state.consumedCount,
                wasted: viewModel.state.wastedCount,
                wasteRate: viewModel.state.wasteRate,
                hasHistory: viewModel.state.hasHistory,
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
        let id: String
        let count: Int
        let color: Color
    }

    struct StatusChartSection: View {
        let expired: Int
        let nearExpiry: Int
        let fresh: Int

        private var total: Int { expired + nearExpiry + fresh }
        private var slices: [StatusSlice] {
            [
                .init(id: "已過期", count: expired, color: expiryColor(.expired)),
                .init(id: "3 天內到期", count: nearExpiry, color: expiryColor(.nearExpiry)),
                .init(id: "保存期限內", count: fresh, color: expiryColor(.fresh)),
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
            .frame(width: 120, height: 120)
            .overlay {
                VStack(spacing: 0) {
                    Text("\(total)")
                        .font(.title2.bold())
                    Text("項")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }

        @ViewBuilder private func legend() -> some View {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(slices) { slice in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(slice.color)
                            .frame(width: 10, height: 10)
                        Text(LocalizedStringKey(slice.id))
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
                            Text("\(Int((wasteRate * 100).rounded()))%")
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
