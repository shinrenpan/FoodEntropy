import Foundation
import UserNotifications

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
    var onRoute: (@MainActor (Router) -> Void)?

    // TODO: Phase 11 — 換成正式託管的隱私權政策頁面 URL。
    static let privacyPolicyURL = URL(string: "https://shinrenpan.github.io/FoodEntropy/privacy")!

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
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
            state.notificationStatus = await Self.currentNotificationStatus()

        case .removeAdsDidTap, .restoreDidTap:
            state.showComingSoon = true   // 廣告 / IAP 上線後開放

        case let .iCloudSyncToggled(isOn):
            defaults.set(isOn, forKey: AppPreferenceKey.iCloudSyncEnabled)
            state.iCloudSyncEnabled = isOn
            state.showRestartNotice = true   // 重啟才實際生效（02-architecture §6）

        case .notificationDidTap:
            onRoute?(.openSystemSettings)

        case .privacyPolicyDidTap:
            onRoute?(.openPrivacyPolicy(Self.privacyPolicyURL))
        }
    }
}

// MARK: - Router

extension SettingsViewModel {
    enum Router: Sendable {
        case openSystemSettings
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

    static func currentNotificationStatus() async -> State.NotificationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return .authorized
        case .denied: return .denied
        default: return .notDetermined
        }
    }
}
