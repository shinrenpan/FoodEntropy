import Charts
import SwiftUI

struct AnalyticsView: View {
    let viewModel: AnalyticsViewModel

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

            BucketSection(title: "已過期未處理", items: viewModel.state.expired)
            BucketSection(title: "3 天內到期", items: viewModel.state.nearExpiry)
            BucketSection(title: "保存期限內", items: viewModel.state.fresh)
        }
        .listStyle(.insetGrouped)
        .onAppear {
            Task { await viewModel.doAction(.view(.onAppear)) }
        }
        .alert("清除歷史統計？", isPresented: $bVM.state.showClearHistoryConfirm) {
            Button("清除", role: .destructive) {
                Task { await viewModel.doAction(.view(.clearHistoryConfirmed)) }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("將刪除所有「已使用 / 丟棄」紀錄，浪費統計將歸零。此操作無法復原。")
        }
    }
}

// MARK: - 現況甜甜圈

private extension AnalyticsView {
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

private extension AnalyticsView {
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

// MARK: - 分桶明細（唯讀）

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
                        FoodRowView(item: item)   // 唯讀，無互動
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
    vm.state.consumedCount = 12
    vm.state.wastedCount = 3
    vm.state.hasHistory = true
    return AnalyticsView(viewModel: vm)
}

#Preview("空狀態") {
    AnalyticsView(viewModel: AnalyticsViewModel(manager: try! SwiftDataManager(inMemory: true)))
}
#endif
