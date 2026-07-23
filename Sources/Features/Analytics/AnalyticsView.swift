import SwiftUI

struct AnalyticsView: View {
    let viewModel: AnalyticsViewModel

    var body: some View {
        List {
            BucketSection(title: "已過期未處理", items: viewModel.state.expired)
            BucketSection(title: "3 天內到期", items: viewModel.state.nearExpiry)
            BucketSection(title: "保存期限內", items: viewModel.state.fresh)
        }
        .listStyle(.insetGrouped)
        .onAppear {
            Task { await viewModel.doAction(.view(.onAppear)) }
        }
    }
}

// MARK: - L2

private extension AnalyticsView {
    struct BucketSection: View {
        let title: LocalizedStringKey
        let items: [FoodItem]

        var body: some View {
            Section {
                if items.isEmpty {
                    Text("沒有項目")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(items) { item in
                        FoodRowView(item: item)   // 唯讀，無任何互動
                    }
                }
            } header: {
                HStack {
                    Text(title)
                    Spacer()
                    Text("\(items.count) 項")
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("有資料") {
    let vm = AnalyticsViewModel(manager: try! SwiftDataManager(inMemory: true))
    vm.state.expired = [FoodItem.mocks[0]]
    vm.state.nearExpiry = Array(FoodItem.mocks[1...2])
    vm.state.fresh = [FoodItem.mocks[3]]
    return AnalyticsView(viewModel: vm)
}

#Preview("空狀態") {
    AnalyticsView(viewModel: AnalyticsViewModel(manager: try! SwiftDataManager(inMemory: true)))
}
#endif
