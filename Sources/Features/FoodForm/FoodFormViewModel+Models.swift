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

        // 儲存進行中。寫入本身同步，但其後的請求權限與重建排程都是 await，
        // 表單在那段期間仍在畫面上——沒有這個旗標，第二次點擊會再建一筆。
        var isSaving: Bool = false
        // 上一次儲存寫入失敗。表單不關閉，改以警示告知（見 food-form-ui）。
        var showSaveFailure: Bool = false

        // 名稱去頭尾空白後非空 → 可儲存。價格為選填，刻意不納入此條件。
        // 刻意不含 isSaving：food-form-ui 有獨立的「名稱不得空白」requirement，
        // 混入進行中狀態會讓那條 requirement 失去精確的對應物。
        // 進行中的把關在 saveDidTap 的 guard 與 canSubmit。
        var isSaveEnabled: Bool {
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        /// 儲存鈕是否可用：名稱合格且沒有儲存正在進行。
        var canSubmit: Bool { isSaveEnabled && !isSaving }
    }
}
