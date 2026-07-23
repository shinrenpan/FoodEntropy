import Foundation

@Observable
@MainActor
final class SettingsViewModel {
    enum Action: Sendable {
        case view(ViewAction)
    }

    var state: State = .init()

    @ObservationIgnored
    private let defaults: UserDefaults

    @ObservationIgnored
    private let notifications: NotificationService

    @ObservationIgnored
    var onRoute: (@MainActor (Router) -> Void)?

    // TODO: Phase 11 — 換成正式託管的隱私權政策頁面 URL。
    static let privacyPolicyURL = URL(string: "https://shinrenpan.github.io/FoodEntropy/privacy")!

    init(defaults: UserDefaults = .standard, notifications: NotificationService = .shared) {
        self.defaults = defaults
        self.notifications = notifications
    }

    func doAction(_ action: Action) async {
        switch action {
        case let .view(action): await handleViewAction(action)
        }
    }
}

// MARK: - ViewAction

extension SettingsViewModel {
    enum ViewAction: Sendable {
        case onAppear
        case removeAdsDidTap       // v1 stub（IAP 延後）
        case restoreDidTap         // v1 stub
        case iCloudSyncToggled(Bool)
        case notificationDidTap
        case privacyPolicyDidTap
    }

    private func handleViewAction(_ action: ViewAction) async {
        switch action {
        case .onAppear:
            state.iCloudSyncEnabled = defaults.bool(forKey: AppPreferenceKey.iCloudSyncEnabled)
            state.versionText = Self.appVersionText
            state.notificationStatus = await notifications.authorizationStatus()

        case .removeAdsDidTap, .restoreDidTap:
            state.showComingSoon = true   // 廣告 / IAP 上線後開放

        case let .iCloudSyncToggled(isOn):
            defaults.set(isOn, forKey: AppPreferenceKey.iCloudSyncEnabled)
            state.iCloudSyncEnabled = isOn
            state.showRestartNotice = true   // 重啟才實際生效（02-architecture §6）

        case .notificationDidTap:
            switch state.notificationStatus {
            case .notDetermined:
                // 還沒問過 → 直接請求權限（跳系統彈窗），而非導向系統設定。
                state.notificationStatus = await notifications.requestAuthorizationIfNeeded()
            case .denied, .authorized:
                // 已決定 → 只能到系統設定調整。
                onRoute?(.openNotificationSettings)
            }

        case .privacyPolicyDidTap:
            onRoute?(.openPrivacyPolicy(Self.privacyPolicyURL))
        }
    }
}

// MARK: - Router

extension SettingsViewModel {
    enum Router: Sendable {
        case openNotificationSettings
        case openPrivacyPolicy(URL)
    }
}

// MARK: - Helpers

private extension SettingsViewModel {
    static var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}
