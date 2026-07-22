import Foundation

@Observable
@MainActor
final class FoodFormViewModel {
    enum Action: Sendable {
        case view(ViewAction)
    }

    var state: State

    @ObservationIgnored
    private let mode: FoodFormMode

    @ObservationIgnored
    private let manager: SwiftDataManager

    @ObservationIgnored
    private let original: Snapshot

    @ObservationIgnored
    var onRoute: (@MainActor (Router) -> Void)?

    init(mode: FoodFormMode, manager: SwiftDataManager) {
        self.mode = mode
        self.manager = manager

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
        }
        self.state = initial
        self.original = Snapshot(state: initial)
    }

    var navigationTitle: String {
        switch mode {
        case .add: "新增食材"
        case .edit: "編輯食材"
        }
    }

    func doAction(_ action: Action) async {
        switch action {
        case let .view(action): await handleViewAction(action)
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
                state.expiryDate = date   // 到期日不得早於購買日（03-screens/form.md 驗證 2）
            }

        case let .imagePicked(data):
            state.imageData = data

        case .removeImage:
            state.imageData = nil

        case .saveDidTap:
            guard state.isSaveEnabled else { return }
            save()
            onRoute?(.close)

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

    private func save() {
        let name = state.name.trimmingCharacters(in: .whitespacesAndNewlines)
        switch mode {
        case .add:
            manager.create(
                name: name,
                purchaseDate: state.purchaseDate,
                expiryDate: state.expiryDate,
                imageData: state.imageData
            )
        case let .edit(item):
            manager.update(
                id: item.id,
                name: name,
                purchaseDate: state.purchaseDate,
                expiryDate: state.expiryDate,
                imageData: state.imageData
            )
        }
        // TODO: Phase 7 — 首次成功儲存請求通知權限；依到期日排程 / 重排通知
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

// MARK: - Snapshot（dirty 比對用，不含 UI-only 欄位）

private extension FoodFormViewModel {
    struct Snapshot: Equatable {
        let name: String
        let purchaseDate: Date
        let expiryDate: Date
        let imageData: Data?

        init(state: State) {
            name = state.name
            purchaseDate = state.purchaseDate
            expiryDate = state.expiryDate
            imageData = state.imageData
        }
    }
}
