import Foundation

// 單一效期分桶的食材清單（見 home-ui）。
//
// 這個畫面存在的理由：首頁改成卡片堆疊後不再渲染食材列，而列的四個動作
// （點擊／左滑／右滑／長按）是 List 免費提供的。把清單放進獨立畫面，
// 那四個動作完全不必自行以手勢重寫。
@Observable
@MainActor
final class BucketListViewModel {
    enum Action: Sendable {
        case view(ViewAction)
        case dataResponse(DataResponse)
    }

    var state: State = .init()

    /// 這份清單代表哪一個效期分桶。建立後不變。
    let bucket: ExpiryStatus

    @ObservationIgnored
    private let manager: SwiftDataManager

    @ObservationIgnored
    private let notifications: NotificationService

    @ObservationIgnored
    var onRoute: (@MainActor (Router) -> Void)?

    init(
        bucket: ExpiryStatus,
        manager: SwiftDataManager,
        notifications: NotificationService = .shared
    ) {
        self.bucket = bucket
        self.manager = manager
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

extension BucketListViewModel {
    enum ViewAction: Sendable {
        case onAppear
        case doneDidTap
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

        case .doneDidTap:
            onRoute?(.close)

        case let .rowDidTap(item):
            onRoute?(.toEdit(item))

        case let .consumeDidTap(item):
            try? manager.markConsumed(id: item.id)
            await reloadAndReschedule()

        case let .wasteDidTap(item):
            try? manager.markWasted(id: item.id)
            await reloadAndReschedule()

        case let .deleteDidTap(item):
            state.pendingDeleteItem = item

        case .deleteConfirmed:
            if let item = state.pendingDeleteItem {
                try? manager.delete(id: item.id)
            }
            state.pendingDeleteItem = nil
            await reloadAndReschedule()

        case .deleteCancelled:
            state.pendingDeleteItem = nil

        case let .extendDidTap(item):
            state.extendingItem = item

        case let .extendCommitted(newExpiry):
            if let item = state.extendingItem {
                try? manager.update(
                    id: item.id,
                    name: item.name,
                    purchaseDate: item.purchaseDate,
                    expiryDate: newExpiry,
                    imageData: item.imageData,
                    price: item.price   // 延長效期只改到期日，其餘欄位原樣帶回
                )
            }
            state.extendingItem = nil
            await reloadAndReschedule()

        case .extendCancelled:
            state.extendingItem = nil
        }
    }

    private func reload() async {
        let active = manager.fetchActiveFoods()
        await doAction(.dataResponse(.loaded(active: active)))
    }

    // 資料變動後：重載 + 以當前 active 重建通知排程（DEBUG 用 10 秒立即驗證）。
    private func reloadAndReschedule() async {
        let active = manager.fetchActiveFoods()
        await doAction(.dataResponse(.loaded(active: active)))
        await notifications.reconcile(activeFoods: active, immediateTestFire: true)
    }
}

// MARK: - Router

extension BucketListViewModel {
    enum Router: Sendable {
        case toEdit(FoodItem)
        case close
    }
}

// MARK: - DataResponse

extension BucketListViewModel {
    enum DataResponse: Sendable {
        case loaded(active: [FoodItem])
    }

    private func handleDataResponse(_ response: DataResponse) async {
        switch response {
        case let .loaded(active):
            // 分桶邏輯與首頁共用同一份，兩處顯示的內容必須一致。
            let summary = FoodStatusSummary(active: active)
            state.items = switch bucket {
            case .expired: summary.expired
            case .nearExpiry: summary.nearExpiry
            case .fresh: summary.fresh
            }
        }
    }
}
