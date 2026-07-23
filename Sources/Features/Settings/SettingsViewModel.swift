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
    private let store: StoreManager

    @ObservationIgnored
    var onRoute: (@MainActor (Router) -> Void)?

    // 隱私權政策頁（GitHub Pages，中英雙語）；同一 URL 亦填入 App Store Connect。
    static let privacyPolicyURL = URL(string: "https://shinrenpan.github.io/FoodEntropy/privacy")!

    init(
        store: StoreManager,
        defaults: UserDefaults = .standard,
        notifications: NotificationService = .shared
    ) {
        self.store = store
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
        case removeAdsDidTap       // 購買移除廣告
        case restoreDidTap         // 還原購買
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
            state.adsRemoved = store.adsRemoved
            state.removeAdsPriceText = store.removeAdsProduct?.displayPrice ?? ""

        case .removeAdsDidTap:
            guard !state.adsRemoved, !state.purchaseInFlight else { return }
            state.purchaseInFlight = true
            do {
                _ = try await store.purchaseRemoveAds()
            } catch {
                state.showPurchaseError = true
            }
            state.adsRemoved = store.adsRemoved   // 以 entitlement 為準（含使用者取消 → 維持 false）
            state.purchaseInFlight = false

        case .restoreDidTap:
            guard !state.purchaseInFlight else { return }
            state.purchaseInFlight = true
            await store.restore()
            state.adsRemoved = store.adsRemoved
            state.purchaseInFlight = false

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
