import Foundation

// MARK: - State

extension SettingsViewModel {
    struct State: Equatable, Sendable {
        var iCloudSyncEnabled: Bool = false        // 偏好值（重啟才實際生效）
        var notificationStatus: NotificationAuthStatus = .notDetermined
        var versionText: String = ""
        var showRestartNotice: Bool = false        // iCloud 切換後提示

        // IAP 移除廣告
        var adsRemoved: Bool = false               // 是否已購買移除廣告
        var removeAdsPriceText: String = ""        // 商品價格（StoreKit displayPrice，載入後才有）
        var purchaseInFlight: Bool = false         // 購買 / 還原進行中（停用按鈕）
        var showPurchaseError: Bool = false        // 購買失敗提示
    }
}
