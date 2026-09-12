import Foundation

// Intent 與 scene 之間交接導航目標的暫存處（見 navigation、app-intents 決策十二）。
//
// 為什麼不直接 `UIApplication.shared.open(url)`：那條路在 Spotlight 點擊（使用者
// 在前景操作）可行，但 **Siri 觸發時 app 不在前景，非前景 app 呼叫 open 會被系統
// 擋掉**，結果是進度轉完就什麼都沒發生（2026-09-12 實機：Spotlight 三種狀態全過，
// Siri 兩種狀態全失敗）。
//
// 改為單純記下目標，由 `SceneDelegate` 在 scene 連上或回到前景時取用。
// `OpenIntent` 的 `openAppWhenRun` 會把 app 帶到前景，所以一定有取用時機。
@MainActor
enum PendingDeeplink {
    /// 有人放了一個待處理目標。
    static let didSetNotification = Notification.Name("PendingDeeplinkDidSet")

    private static var stored: Deeplink?

    /// 放入待處理目標並通知已連上的 scene。
    /// app 已在前景時（例如從 app 內下拉 Spotlight）沒有生命週期轉換可依附，
    /// 因此需要這個通知。
    static func set(_ deeplink: Deeplink) {
        stored = deeplink
        NotificationCenter.default.post(name: didSetNotification, object: nil)
    }

    /// 取出並清空。多個取用時機共用同一份，取過就沒了，因此重複呼叫是安全的。
    static func take() -> Deeplink? {
        defer { stored = nil }
        return stored
    }
}
