import Foundation

@Observable
@MainActor
final class FoodFormViewModel {
    enum Action: Sendable {
        case view(ViewAction)
        case dataResponse(DataResponse)
    }

    var state: State

    @ObservationIgnored
    private let mode: FoodFormMode

    @ObservationIgnored
    private let manager: SwiftDataManager

    @ObservationIgnored
    private let notifications: NotificationService

    @ObservationIgnored
    private let original: Snapshot

    @ObservationIgnored
    var onRoute: (@MainActor (Router) -> Void)?

    init(mode: FoodFormMode, manager: SwiftDataManager, notifications: NotificationService = .shared) {
        self.mode = mode
        self.manager = manager
        self.notifications = notifications

        var initial = State()
        switch mode {
        case .add:
            initial.purchaseDate = .now
            initial.expiryDate = Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now
        case let .edit(item):
            initial.name = item.name
            initial.purchaseDate = item.purchaseDate
            initial.expiryDate = item.expiryDate
            initial.imageData = item.imageData
            initial.price = item.price
        }
        self.state = initial
        self.original = Snapshot(state: initial)
    }

    var navigationTitle: String {
        switch mode {
        case .add: String(localized: "Add Food")
        case .edit: String(localized: "Edit Food")
        }
    }

    func doAction(_ action: Action) async {
        switch action {
        case let .view(action): await handleViewAction(action)
        case let .dataResponse(response): await handleDataResponse(response)
        }
    }
}

// MARK: - ViewAction

extension FoodFormViewModel {
    enum ViewAction: Sendable {
        case purchaseDateChanged(Date)   // 帶「頂推到期日」邏輯，故走 action
        case imagePicked(Data?)          // 壓縮後結果（拍照 / 相簿共用）
        case removeImage
        case saveDidTap
        case dismissDidTap               // 返回：dirty → 確認，否則 close
        case discardConfirmed
        case discardCancelled
    }

    private func handleViewAction(_ action: ViewAction) async {
        switch action {
        case let .purchaseDateChanged(date):
            state.purchaseDate = date
            if date > state.expiryDate {
                state.expiryDate = date   // 到期日不得早於購買日（見 food-form-ui）
            }

        case let .imagePicked(data):
            state.imageData = data

        case .removeImage:
            state.imageData = nil

        case .saveDidTap:
            // isSaving 也擋在這裡而不只靠鈕失效：鍵盤快捷、輔助技術，
            // 以及 SwiftUI 在失效生效前已派發的觸發都繞得過視覺狀態。
            guard state.isSaveEnabled, !state.isSaving else { return }
            state.isSaving = true
            await save()

        case .dismissDidTap:
            if isDirty {
                state.showDiscardConfirm = true
            } else {
                onRoute?(.close)
            }

        case .discardConfirmed:
            onRoute?(.close)

        case .discardCancelled:
            state.showDiscardConfirm = false
        }
    }

    /// 寫入 → 請求權限 → 重建排程 → 回報成功（見 food-form-ui）。
    ///
    /// 寫入失敗即就地中止：請求權限與重建排程的對象都是「剛寫進去的那筆」，
    /// 而它不存在。首次儲存就失敗還跳通知授權彈窗尤其突兀——使用者會在一個
    /// 什麼都沒發生的操作後被要求授權。
    private func save() async {
        let name = state.name.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            switch mode {
            case .add:
                _ = try manager.create(
                    name: name,
                    purchaseDate: state.purchaseDate,
                    expiryDate: state.expiryDate,
                    imageData: state.imageData,
                    price: state.price
                )
            case let .edit(item):
                try manager.update(
                    id: item.id,
                    name: name,
                    purchaseDate: state.purchaseDate,
                    expiryDate: state.expiryDate,
                    imageData: state.imageData,
                    price: state.price
                )
            }
        } catch {
            await doAction(.dataResponse(.saveFailed))
            return
        }
        // 首次儲存請求權限（notDetermined 才跳彈窗）→ 以當前 active 重建排程（DEBUG 用 10 秒立即驗證）。
        await notifications.requestAuthorizationIfNeeded()
        await notifications.reconcile(activeFoods: manager.fetchActiveFoods(), immediateTestFire: true)
        await doAction(.dataResponse(.saveSucceeded))
    }

    private var isDirty: Bool {
        Snapshot(state: state) != original
    }
}

// MARK: - Router

extension FoodFormViewModel {
    enum Router: Sendable {
        case close
    }
}

// MARK: - DataResponse

extension FoodFormViewModel {
    enum DataResponse: Sendable {
        case saveSucceeded
        case saveFailed
    }

    // 關閉表單與顯示失敗警示都收在這裡，而不是寫入的當下：
    // SwiftDataManager 是具體型別，測試無法令其寫入失敗，
    // 把結果表達成 action 後，失敗路徑才驅動得起來（見 mvvmc-testing）。
    private func handleDataResponse(_ response: DataResponse) async {
        switch response {
        case .saveSucceeded:
            state.isSaving = false
            onRoute?(.close)

        case .saveFailed:
            // 先解除進行中，使用者關掉警示後可以直接再按一次儲存。
            state.isSaving = false
            state.showSaveFailure = true
        }
    }
}

// MARK: - Snapshot（dirty 比對用，不含 UI-only 欄位）

private extension FoodFormViewModel {
    struct Snapshot: Equatable {
        let name: String
        let purchaseDate: Date
        let expiryDate: Date
        let imageData: Data?
        let price: Double?

        init(state: State) {
            name = state.name
            purchaseDate = state.purchaseDate
            expiryDate = state.expiryDate
            imageData = state.imageData
            price = state.price
        }
    }
}
