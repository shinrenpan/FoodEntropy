import Foundation

@Observable
@MainActor
final class HomeViewModel {
    enum Action: Sendable {
        case view(ViewAction)
        case dataResponse(DataResponse)
    }

    static let wasteWindowDays = 30   // 浪費率統計視窗

    var state: State = .init()

    @ObservationIgnored
    private let manager: SwiftDataManager

    @ObservationIgnored
    private let notifications: NotificationService

    @ObservationIgnored
    private let store: StoreManager

    @ObservationIgnored
    var onRoute: (@MainActor (Router) -> Void)?

    init(
        manager: SwiftDataManager,
        store: StoreManager,
        notifications: NotificationService = .shared
    ) {
        self.manager = manager
        self.store = store
        self.notifications = notifications
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
        case clearHistoryDidTap            // 清除歷史統計 → 顯示確認
        case clearHistoryConfirmed
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
            await reloadAndReschedule()

        case let .wasteDidTap(item):
            manager.markWasted(id: item.id)
            await reloadAndReschedule()

        case let .deleteDidTap(item):
            state.pendingDeleteItem = item

        case .deleteConfirmed:
            if let item = state.pendingDeleteItem {
                manager.delete(id: item.id)
            }
            state.pendingDeleteItem = nil
            await reloadAndReschedule()

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
            }
            state.extendingItem = nil
            await reloadAndReschedule()

        case .extendCancelled:
            state.extendingItem = nil

        case .clearHistoryDidTap:
            state.showClearHistoryConfirm = true

        case .clearHistoryConfirmed:
            manager.deleteResolvedFoods()
            state.showClearHistoryConfirm = false
            await reload()   // 統計歸零、清除鈕收起
        }
    }

    private func reload() async {
        let active = manager.fetchActiveFoods()
        let resolved = manager.fetchResolvedFoods()
        state.adsRemoved = store.adsRemoved   // 持有移除廣告 entitlement 時隱藏 AdSlotView
        await doAction(.dataResponse(.loaded(active: active, resolved: resolved)))
    }

    // 資料變動後：重載 + 以當前 active 重建通知排程（DEBUG 用 10 秒立即驗證）。
    private func reloadAndReschedule() async {
        await reload()
        await notifications.reconcile(activeFoods: state.items, immediateTestFire: true)
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
            // all-time：只要有任何已處理紀錄就露出清除鈕（含 30 天視窗外的舊資料）。
            state.hasHistory = !resolved.isEmpty
        }
    }
}
