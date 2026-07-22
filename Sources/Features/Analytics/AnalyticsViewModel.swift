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
            let foods = manager.fetchActiveFoods()
            await doAction(.dataResponse(.foodsLoaded(foods)))
        }
    }
}

// MARK: - DataResponse

extension AnalyticsViewModel {
    enum DataResponse: Sendable {
        case foodsLoaded([FoodItem])
    }

    private func handleDataResponse(_ response: DataResponse) async {
        switch response {
        case let .foodsLoaded(foods):
            // 依效期狀態分三桶；foods 已依到期日升冪，故桶內順序天然正確。
            state.expired = foods.filter { $0.expiryStatus() == .expired }
            state.nearExpiry = foods.filter { $0.expiryStatus() == .nearExpiry }
            state.fresh = foods.filter { $0.expiryStatus() == .fresh }
        }
    }
}
