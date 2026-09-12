import AppIntents
import Foundation

// 動作完成後要告訴使用者什麼（見 app-intents）。
//
// 為什麼需要這個：不開 app 的 Intent 執行完是靜默的——使用者對 Siri 說
// 「mark this as used」，若不回話也不顯示任何東西，無從判斷成功與否。
// Apple 的建議是回 dialog（給語音）與 snippet（給畫面），兩者分工。
enum FoodItemActionOutcome: CaseIterable, Sendable {
    case added
    case consumed
    case wasted
    case extended

    /// 已離開 active 清單者，snippet 不顯示剩餘天數——那個數字對已處理的食材沒有意義。
    var leavesList: Bool {
        switch self {
        case .consumed, .wasted: true
        case .added, .extended: false
        }
    }

    var symbolName: String {
        switch self {
        case .added: "plus.circle.fill"
        case .consumed: "checkmark.circle.fill"
        case .wasted: "trash.circle.fill"
        case .extended: "calendar.badge.plus"
        }
    }

    /// Siri 唸出來的句子。`supporting` 留空讓系統自行決定簡短程度。
    func dialog(name: String) -> IntentDialog {
        switch self {
        case .added: IntentDialog("Added \(name).")
        case .consumed: IntentDialog("Marked \(name) as used.")
        case .wasted: IntentDialog("Marked \(name) as discarded.")
        case .extended: IntentDialog("Updated the expiry date for \(name).")
        }
    }
}
