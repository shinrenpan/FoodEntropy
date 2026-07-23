import Foundation
import UserNotifications

// 通知授權狀態（Settings 與 Service 共用）。
enum NotificationAuthStatus: String, Sendable {
    case authorized, denied, notDetermined
}

// 到期通知服務（02-architecture §8）。
// 採「reconcile」策略：以當前 active 清單重建待發通知，天然涵蓋
// 排程 / 取消 / 重排，並以「最近到期優先」滿足 iOS 64 則上限。
@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private let active: Bool               // 測試注入 false → 全部 no-op，避免打到系統
    private let center = UNUserNotificationCenter.current()

    private static let fireHour = 9        // 到期當天 09:00
    private static let maxScheduled = 60   // iOS 上限 64，留 headroom

    init(active: Bool = true) {
        self.active = active
    }

    // MARK: - 權限

    func authorizationStatus() async -> NotificationAuthStatus {
        guard active else { return .notDetermined }
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return .authorized
        case .denied: return .denied
        default: return .notDetermined
        }
    }

    // 僅在 notDetermined 時跳彈窗（首次儲存 / 設定列使用）。回傳最終狀態。
    @discardableResult
    func requestAuthorizationIfNeeded() async -> NotificationAuthStatus {
        guard active else { return .notDetermined }
        if await authorizationStatus() == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }
        return await authorizationStatus()
    }

    // MARK: - 排程對帳

    // 以當前 active 食材重建待發通知：清空 → 取「未過 09:00」者、依到期日升冪、
    // 取最近 maxScheduled 筆重新排程。任何新增 / 編輯 / 移除後呼叫即保持一致。
    func reconcile(activeFoods: [FoodItem]) async {
        guard active else { return }
        center.removeAllPendingNotificationRequests()

        let calendar = Calendar.current
        let now = Date.now
        let requests = activeFoods
            .compactMap { food -> (FoodItem, Date)? in
                guard let fire = fireDate(for: food.expiryDate, calendar: calendar), fire > now else { return nil }
                return (food, fire)
            }
            .sorted { $0.1 < $1.1 }
            .prefix(Self.maxScheduled)
            .map { makeRequest(for: $0.0, fireDate: $0.1, calendar: calendar) }

        for request in requests {
            try? await center.add(request)
        }
    }

    // MARK: - Private

    private func fireDate(for expiryDate: Date, calendar: Calendar) -> Date? {
        var comps = calendar.dateComponents([.year, .month, .day], from: expiryDate)
        comps.hour = Self.fireHour
        comps.minute = 0
        return calendar.date(from: comps)
    }

    private func makeRequest(for food: FoodItem, fireDate: Date, calendar: Calendar) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "食材到期提醒")
        content.body = String(localized: "「\(food.name)」今天到期，記得處理。")
        content.sound = .default
        content.userInfo = ["deeplink": "foodentropy://home"]   // 點擊 → 首頁（SceneDelegate 已處理）

        let triggerComps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: false)
        return UNNotificationRequest(identifier: food.id.uuidString, content: content, trigger: trigger)
    }
}
