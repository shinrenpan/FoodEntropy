import Foundation

// MARK: - State

extension FoodFormViewModel {
    struct State: Equatable, Sendable {
        var name: String = ""
        var purchaseDate: Date = .now
        var expiryDate: Date = .now
        var imageData: Data? = nil
        var price: Double? = nil          // 選填，這筆記錄的總花費；不列入 isSaveEnabled
        var showDiscardConfirm: Bool = false

        // 名稱去頭尾空白後非空 → 可儲存。價格為選填，刻意不納入此條件。
        var isSaveEnabled: Bool {
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}
