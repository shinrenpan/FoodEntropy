import Foundation
import Testing
@testable import FoodEntropy

// Widget 的 timeline 刷新點。效期是日期的函式——同一筆資料跨過午夜就換桶，
// 因此刷新點必須落在次日零時，早一秒或晚一天都會讓 Widget 顯示過期的分桶結果。
@MainActor
struct DayBoundaryTests {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Taipei")!
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    @Test
    func `一般時刻的下一個邊界是隔天零時`() {
        let next = DayBoundary.next(after: date(2026, 8, 12, 14, 30), calendar: calendar)
        #expect(next == date(2026, 8, 13, 0, 0))
    }

    @Test
    func `接近午夜時仍落在隔天零時而非當天`() {
        let next = DayBoundary.next(after: date(2026, 8, 12, 23, 59), calendar: calendar)
        #expect(next == date(2026, 8, 13, 0, 0))
    }

    @Test
    func `正好零時的下一個邊界是再隔一天`() {
        // 邊界本身已經過了，再回傳同一時刻會讓 timeline 立刻失效並重複刷新。
        let next = DayBoundary.next(after: date(2026, 8, 12, 0, 0), calendar: calendar)
        #expect(next == date(2026, 8, 13, 0, 0))
    }

    @Test
    func `跨月時進入下個月的第一天`() {
        let next = DayBoundary.next(after: date(2026, 8, 31, 20, 0), calendar: calendar)
        #expect(next == date(2026, 9, 1, 0, 0))
    }

    @Test
    func `跨年時進入下一年的元旦`() {
        let next = DayBoundary.next(after: date(2026, 12, 31, 23, 30), calendar: calendar)
        #expect(next == date(2027, 1, 1, 0, 0))
    }

    @Test
    func `回傳值必定晚於輸入時刻`() {
        for hour in 0...23 {
            let now = date(2026, 8, 12, hour, 0)
            #expect(DayBoundary.next(after: now, calendar: calendar) > now)
        }
    }
}
