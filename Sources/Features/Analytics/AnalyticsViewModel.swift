import Foundation

@Observable
@MainActor
final class AnalyticsViewModel {
    enum Action: Sendable {
        case view(ViewAction)
        case dataResponse(DataResponse)
    }

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
    }

    private func handleViewAction(_ action: ViewAction) async {
        switch action {
        case .onAppear:
            let active = manager.fetchActiveFoods()
            let resolved = manager.fetchResolvedFoods()
            await doAction(.dataResponse(.loaded(active: active, resolved: resolved)))
        }
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
            // 歷史統計：吃掉 / 丟棄計數。
            state.consumedCount = resolved.filter { $0.status == .consumed }.count
            state.wastedCount = resolved.filter { $0.status == .wasted }.count
        }
    }
}
