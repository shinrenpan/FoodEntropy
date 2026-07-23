import Foundation

@Observable
@MainActor
final class HomeViewModel {
    enum Action: Sendable {
        case view(ViewAction)
        case dataResponse(DataResponse)
    }

    var state: State = .init()

    @ObservationIgnored
    private let manager: SwiftDataManager

    @ObservationIgnored
    var onRoute: (@MainActor (Router) -> Void)?

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

extension HomeViewModel {
    enum ViewAction: Sendable {
        case onAppear
        case addDidTap
        case rowDidTap(FoodItem)
        case consumeDidTap(FoodItem)
        case wasteDidTap(FoodItem)
        case deleteDidTap(FoodItem)        // 顯示刪除確認
        case deleteConfirmed
        case deleteCancelled
        case extendDidTap(FoodItem)        // 顯示延長 date picker
        case extendCommitted(Date)
        case extendCancelled
    }

    private func handleViewAction(_ action: ViewAction) async {
        switch action {
        case .onAppear:
            await reload()

        case .addDidTap:
            onRoute?(.toAdd)

        case let .rowDidTap(item):
            onRoute?(.toEdit(item))

        case let .consumeDidTap(item):
            manager.markConsumed(id: item.id)
            // TODO: Phase 7 — 取消該食材通知排程
            await reload()

        case let .wasteDidTap(item):
            manager.markWasted(id: item.id)
            // TODO: Phase 7 — 取消該食材通知排程
            await reload()

        case let .deleteDidTap(item):
            state.pendingDeleteItem = item

        case .deleteConfirmed:
            if let item = state.pendingDeleteItem {
                manager.delete(id: item.id)
                // TODO: Phase 7 — 取消該食材通知排程
            }
            state.pendingDeleteItem = nil
            await reload()

        case .deleteCancelled:
            state.pendingDeleteItem = nil

        case let .extendDidTap(item):
            state.extendingItem = item

        case let .extendCommitted(newExpiry):
            if let item = state.extendingItem {
                manager.update(
                    id: item.id,
                    name: item.name,
                    purchaseDate: item.purchaseDate,
                    expiryDate: newExpiry,
                    imageData: item.imageData
                )
                // TODO: Phase 7 — 依新到期日重排通知
            }
            state.extendingItem = nil
            await reload()

        case .extendCancelled:
            state.extendingItem = nil
        }
    }

    private func reload() async {
        let foods = manager.fetchActiveFoods()
        await doAction(.dataResponse(.foodsLoaded(foods)))
    }
}

// MARK: - Router

extension HomeViewModel {
    enum Router: Sendable {
        case toAdd
        case toEdit(FoodItem)
    }
}

// MARK: - DataResponse

extension HomeViewModel {
    enum DataResponse: Sendable {
        case foodsLoaded([FoodItem])
    }

    private func handleDataResponse(_ response: DataResponse) async {
        switch response {
        case let .foodsLoaded(foods):
            state.items = foods
        }
    }
}
