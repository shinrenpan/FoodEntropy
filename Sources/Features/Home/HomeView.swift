import SwiftUI

struct HomeView: View {
    let viewModel: HomeViewModel

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            FoodListSection(
                items: viewModel.state.items,
                adsRemoved: viewModel.state.adsRemoved,
                send: handleListAction
            )

            FloatingAddButton {
                Task { await viewModel.doAction(.view(.addDidTap)) }
            }
            .padding(20)
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
        .sheet(item: extendItemBinding()) { item in
            ExtendSheet(item: item, send: handleExtendAction)
        }
    }

    // MARK: - L1 協調

    private func handleListAction(_ action: FoodListSection.Action) {
        switch action {
        case let .rowDidTap(item):
            Task { await viewModel.doAction(.view(.rowDidTap(item))) }
        case let .editDidTap(item):
            Task { await viewModel.doAction(.view(.editDidTap(item))) }
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

// MARK: - L2 / L3

private extension HomeView {
    struct FoodListSection: View {
        enum Action: Sendable {
            case rowDidTap(FoodItem)
            case editDidTap(FoodItem)
            case consumeDidTap(FoodItem)
            case wasteDidTap(FoodItem)
            case deleteDidTap(FoodItem)
            case extendDidTap(FoodItem)
        }

        let items: [FoodItem]
        let adsRemoved: Bool
        let send: (Action) -> Void

        var body: some View {
            List {
                if !adsRemoved {
                    Section {
                        AdSlotView()
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }

                if items.isEmpty {
                    emptyHint()
                } else {
                    Section {
                        ForEach(items) { item in
                            row(item)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
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
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) { send(.deleteDidTap(item)) } label: {
                        Label("刪除", systemImage: "trash")
                    }
                }
                .contextMenu {
                    Button { send(.extendDidTap(item)) } label: { Label("延長效期", systemImage: "calendar") }
                    Button { send(.consumeDidTap(item)) } label: { Label("標記已使用", systemImage: "checkmark.circle") }
                    Button { send(.wasteDidTap(item)) } label: { Label("標記丟棄", systemImage: "trash.slash") }
                    Button { send(.editDidTap(item)) } label: { Label("編輯", systemImage: "pencil") }
                    Button(role: .destructive) { send(.deleteDidTap(item)) } label: { Label("刪除", systemImage: "trash") }
                }
        }

        @ViewBuilder private func emptyHint() -> some View {
            Section {
                VStack(spacing: 8) {
                    Image(systemName: "fork.knife")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("目前還沒有食材")
                        .font(.headline)
                    Text("點右下角的＋開始記錄")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
            }
        }
    }

    struct FloatingAddButton: View {
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .frame(width: 56, height: 56)
                    .background(.tint, in: Circle())
                    .foregroundStyle(.white)
                    .shadow(radius: 4, y: 2)
            }
            .accessibilityLabel("新增食材")
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
    return HomeView(viewModel: HomeViewModel(manager: manager))
}

#Preview("空狀態") {
    HomeView(viewModel: HomeViewModel(manager: try! SwiftDataManager(inMemory: true)))
}
#endif
