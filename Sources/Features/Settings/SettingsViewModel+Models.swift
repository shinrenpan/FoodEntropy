import Foundation

// MARK: - State

extension SettingsViewModel {
    struct State: Equatable, Sendable {
        var iCloudSyncEnabled: Bool = false        // 偏好值（重啟才實際生效）
        var notificationStatus: NotificationAuthStatus = .notDetermined
        var versionText: String = ""
        var showRestartNotice: Bool = false        // iCloud 切換後提示
        var showComingSoon: Bool = false           // 移除廣告 / 還原購買 stub 提示
    }
}
