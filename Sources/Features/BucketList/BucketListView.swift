import AppIntents
import SwiftUI

// 單一效期分桶的食材清單（見 home-ui）。
//
// 內容是真正的 `List`，所以列的四個動作——點擊編輯、左滑標記已使用、
// 右滑刪除、長按延長／處置——完全由系統提供，不需自行實作任何手勢。
// 首頁改為卡片堆疊後不再渲染食材列，那些動作就住在這裡。
struct BucketListView: View {
    let viewModel: BucketListViewModel

    var body: some View {
        @Bindable var bVM = viewModel

        List {
            Section {
                if viewModel.state.isEmpty {
                    Text("No items")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(viewModel.state.items) { item in
                        row(item)
                    }
                }
            } footer: {
                // 手勢提示掛在列所在之處（見 home-ui）。
                Text("Tap to edit; swipe to mark used / delete; long-press to extend or discard.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    Task { await viewModel.doAction(.view(.doneDidTap)) }
                }
            }
        }
        .onAppear {
            Task { await viewModel.doAction(.view(.onAppear)) }
        }
        // 資料可能由助理 / Spotlight 在本畫面停留期間改動（見 app-intents 決策八）。
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
        .sheet(item: extendItemBinding()) { item in
            ExtendSheet(item: item, send: handleExtendAction)
        }
    }

    private var title: LocalizedStringKey {
        switch viewModel.bucket {
        case .expired: "Expired, unhandled"
        case .nearExpiry: "Expiring within 3 days"
        case .fresh: "Fresh"
        }
    }

    // MARK: - L1 協調

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
            set: { presented in
                if !presented {
                    Task { await viewModel.doAction(.view(.deleteCancelled)) }
                }
            }
        )
    }

    private func extendItemBinding() -> Binding<FoodItem?> {
        Binding(
            get: { viewModel.state.extendingItem },
            set: { item in
                if item == nil {
                    Task { await viewModel.doAction(.view(.extendCancelled)) }
                }
            }
        )
    }
}

// MARK: - L2

private extension BucketListView {
    @ViewBuilder func row(_ item: FoodItem) -> some View {
        FoodRowView(item: item)
            // 螢幕感知（見 app-intents）：標註掛在真正的食材列上。首頁只有摘要卡，
            // 沒有食材可供解析，因此不帶標註。
            .appEntityIdentifier(EntityIdentifier(for: FoodItemAppEntity.self, identifier: item.id))
            .contentShape(Rectangle())
            .onTapGesture {
                Task { await viewModel.doAction(.view(.rowDidTap(item))) }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    Task { await viewModel.doAction(.view(.consumeDidTap(item))) }
                } label: {
                    Label("Mark as used", systemImage: "checkmark")
                }
                .tint(.green)
            }
            // 刻意不用 role: .destructive：destructive 會讓 SwiftUI 一點擊就自動移除 row，
            // 但本操作需先跳確認 alert（真正刪除由 deleteConfirmed 觸發）。
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                    Task { await viewModel.doAction(.view(.deleteDidTap(item))) }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(.red)
            }
            // 編輯 → 點 row；刪除 → 左滑。長按只放「不在滑動 / 點擊上」的動作。
            .contextMenu {
                Button {
                    Task { await viewModel.doAction(.view(.extendDidTap(item))) }
                } label: { Label("Extend expiry", systemImage: "calendar") }
                Button {
                    Task { await viewModel.doAction(.view(.consumeDidTap(item))) }
                } label: { Label("Mark as Used", systemImage: "checkmark.circle") }
                Button {
                    Task { await viewModel.doAction(.view(.wasteDidTap(item))) }
                } label: { Label("Mark as Discarded", systemImage: "trash.slash") }
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
