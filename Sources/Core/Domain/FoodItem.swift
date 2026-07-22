import Foundation

// 跨 feature 共用的核心 Domain Model（首頁 / 分析 / Form 皆消費）。
// 由 FoodItemEntity.toDomain() 產生；ViewModel / State 只持有此型別，不碰 @Model。
struct FoodItem: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var purchaseDate: Date
    var expiryDate: Date
    var status: RecordStatus
    var resolvedAt: Date?          // 離開 active（consumed / wasted）的時間
    var imageData: Data?           // 壓縮後 JPEG
    let createdAt: Date
}

// MARK: - RecordStatus（stored；持久化於 statusRaw）

enum RecordStatus: String, Sendable {
    case active       // 現存於清單
    case consumed     // 已使用（吃掉）
    case wasted       // 丟棄（過期 / 壞掉）
}

// MARK: - ExpiryStatus（computed；不持久化，由 expiryDate 比對今天算出）

enum ExpiryStatus: String, Sendable {
    case fresh        // 期限內
    case nearExpiry   // 3 天內到期（含到期當天、含第 3 天）
    case expired      // 已過期
}

extension ExpiryStatus {
    /// nearExpiry 的天數門檻（含）。02-architecture §5，可調常數。
    static let nearExpiryWindowDays = 3

    /// 到期日與今天的日曆日差（忽略時分秒）。負值代表已過期。
    static func daysUntil(
        expiryDate: Date,
        today: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        let startToday = calendar.startOfDay(for: today)
        let startExpiry = calendar.startOfDay(for: expiryDate)
        return calendar.dateComponents([.day], from: startToday, to: startExpiry).day ?? 0
    }

    /// 依日曆日差判定狀態。<0 → expired；0…3 → nearExpiry；>3 → fresh。
    static func evaluate(
        expiryDate: Date,
        today: Date = .now,
        calendar: Calendar = .current
    ) -> ExpiryStatus {
        let days = daysUntil(expiryDate: expiryDate, today: today, calendar: calendar)
        if days < 0 { return .expired }
        if days <= nearExpiryWindowDays { return .nearExpiry }
        return .fresh
    }
}

// MARK: - FoodItem 便利計算（呼叫上方純函式；預設以今天為基準）

extension FoodItem {
    func expiryStatus(today: Date = .now, calendar: Calendar = .current) -> ExpiryStatus {
        ExpiryStatus.evaluate(expiryDate: expiryDate, today: today, calendar: calendar)
    }

    func daysUntilExpiry(today: Date = .now, calendar: Calendar = .current) -> Int {
        ExpiryStatus.daysUntil(expiryDate: expiryDate, today: today, calendar: calendar)
    }
}
