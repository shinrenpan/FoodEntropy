import Foundation

// 跨層共用的 UserDefaults 偏好 key（避免魔法字串在多處漂移）。
enum AppPreferenceKey {
    static let iCloudSyncEnabled = "iCloudSyncEnabled"
}
