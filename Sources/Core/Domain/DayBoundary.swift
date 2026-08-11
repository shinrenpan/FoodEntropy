import Foundation

// 跨日邊界。`ExpiryStatus` 是日期的函式（見 food-item），同一筆資料在午夜過後
// 就換桶——Widget 的 timeline 因此必須在每日起始重新計算，否則會顯示過期的分桶結果。
//
// 抽在 Domain 而非 Widget 內：extension 的程式碼進不了測試 target，
// 而「刷新點算得對不對」是這條規則唯一能自動驗證的部分。
enum DayBoundary {
    /// 給定時刻之後的第一個午夜。必定嚴格晚於輸入——
    /// 若在正好零時回傳同一時刻，timeline 會立即失效並反覆刷新。
    static func next(after date: Date, calendar: Calendar = .current) -> Date {
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))
        // startOfDay 對合理輸入不會失敗；真失敗時退一小時後重試，
        // 寧可多刷新一次也不要讓 timeline 停在過去。
        return startOfNextDay ?? date.addingTimeInterval(60 * 60)
    }
}
