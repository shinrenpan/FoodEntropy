import Foundation

@Observable
@MainActor
final class AnalyticsViewModel {
    enum Action: Sendable {
        case view(ViewAction)
        case dataResponse(DataResponse)
    }

    static let wasteWindowDays = 30   // 浪費率統計視窗

    var state: State = .init()

    @ObservationIgnored
    private let manager: SwiftDataManager

    init(manager: SwiftDataManager) {
        self.manager = manager
    }

    func doAction(_ action: Action) async {
        switch action {
        case let .view(action): await handleViewAction(action)
        case let .dataResponse(response): await handleDataResponse(response)
        }
    }
}

// MARK: - ViewAction

extension AnalyticsViewModel {
    enum ViewAction: Sendable {
        case onAppear
        case clearHistoryDidTap      // 清除歷史統計 → 顯示確認
        case clearHistoryConfirmed
    }

    private func handleViewAction(_ action: ViewAction) async {
        switch action {
        case .onAppear:
            await reload()

        case .clearHistoryDidTap:
            state.showClearHistoryConfirm = true

        case .clearHistoryConfirmed:
            manager.deleteResolvedFoods()
            state.showClearHistoryConfirm = false
            await reload()   // 清完重撈，統計歸零、清除鈕收起
        }
    }

    private func reload() async {
        let active = manager.fetchActiveFoods()
        let resolved = manager.fetchResolvedFoods()
        await doAction(.dataResponse(.loaded(active: active, resolved: resolved)))
    }
}

// MARK: - DataResponse

extension AnalyticsViewModel {
    enum DataResponse: Sendable {
        case loaded(active: [FoodItem], resolved: [FoodItem])
    }

    private func handleDataResponse(_ response: DataResponse) async {
        switch response {
        case let .loaded(active, resolved):
            // 現況：依效期狀態分三桶（active 已依到期日升冪，桶內順序天然正確）。
            state.expired = active.filter { $0.expiryStatus() == .expired }
            state.nearExpiry = active.filter { $0.expiryStatus() == .nearExpiry }
            state.fresh = active.filter { $0.expiryStatus() == .fresh }
            // 歷史統計：只計「近 30 天」內處理的（滾動視窗，舊資料自然不影響）。
            let cutoff = Calendar.current.date(byAdding: .day, value: -Self.wasteWindowDays, to: .now) ?? .distantPast
            let windowed = resolved.filter { ($0.resolvedAt ?? .distantPast) >= cutoff }
            state.consumedCount = windowed.filter { $0.status == .consumed }.count
            state.wastedCount = windowed.filter { $0.status == .wasted }.count
            // all-time：只要有任何已處理紀錄就露出清除鈕（含 30 天視窗外的舊資料）
            state.hasHistory = !resolved.isEmpty
        }
    }
}
