import Foundation
import Testing
@testable import FoodEntropy

struct ExpiryStatusTests {
    // 固定基準日（含時分秒，用來驗證「忽略時分秒」）：2026-07-22 15:00。
    private var calendar: Calendar { .current }
    private var today: Date {
        var c = DateComponents()
        c.year = 2026; c.month = 7; c.day = 22; c.hour = 15; c.minute = 0
        return calendar.date(from: c)!
    }

    private func expiry(daysFromToday days: Int) -> Date {
        calendar.date(byAdding: .day, value: days, to: today)!
    }

    @Test("daysUntil 忽略時分秒，等於日曆日差", arguments: [-2, -1, 0, 1, 2, 3, 4, 10])
    func daysUntilMatchesCalendarDiff(days: Int) {
        let result = ExpiryStatus.daysUntil(expiryDate: expiry(daysFromToday: days), today: today, calendar: calendar)
        #expect(result == days)
    }

    @Test("狀態邊界：<0 expired、0…3 nearExpiry、>3 fresh")
    func statusBoundaries() {
        func status(_ days: Int) -> ExpiryStatus {
            ExpiryStatus.evaluate(expiryDate: expiry(daysFromToday: days), today: today, calendar: calendar)
        }
        #expect(status(-2) == .expired)
        #expect(status(-1) == .expired)      // 過期隔天才紅
        #expect(status(0) == .nearExpiry)    // 到期當天 = 黃，非紅
        #expect(status(1) == .nearExpiry)
        #expect(status(3) == .nearExpiry)    // 含第 3 天
        #expect(status(4) == .fresh)
    }

    @Test("到期當天不同時分秒仍判 nearExpiry（忽略時間）")
    func expiryDayIgnoresTimeOfDay() {
        // 到期日設在今天的凌晨 01:00，仍應是 nearExpiry（daysUntil = 0）
        var c = DateComponents()
        c.year = 2026; c.month = 7; c.day = 22; c.hour = 1
        let earlyToday = calendar.date(from: c)!
        #expect(ExpiryStatus.evaluate(expiryDate: earlyToday, today: today, calendar: calendar) == .nearExpiry)
    }
}
