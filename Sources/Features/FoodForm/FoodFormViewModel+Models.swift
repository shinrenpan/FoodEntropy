import Foundation

// MARK: - State

extension FoodFormViewModel {
    struct State: Equatable, Sendable {
        var name: String = ""
        var purchaseDate: Date = .now
        var expiryDate: Date = .now
        var imageData: Data? = nil
        var showDiscardConfirm: Bool = false

        // 名稱去頭尾空白後非空 → 可儲存（03-screens/form.md 驗證 1）
        var isSaveEnabled: Bool {
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}
