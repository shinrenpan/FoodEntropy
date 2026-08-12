import SwiftUI
import WidgetKit

// 主畫面中尺寸 Widget：與首頁「現況」區塊相同的版面，且共用同一份實作
// （widget spec:「The widget and the in-app screen share one presentation
// implementation」）。不做小尺寸與鎖定畫面——前者放不下這個版面，後者是單色渲染。

struct StatusEntry: TimelineEntry {
    let date: Date
    let expired: Int
    let nearExpiry: Int
    let fresh: Int
    /// nil = 無可計算金額 → 該行不渲染。
    let upcomingExpiryCost: Double?

    // 攜帶 Domain 值而非 @Model：entry 會跨 process 傳遞，
    // 帶 context-bound 的持久化物件不安全，也違反分層規範。
    init(date: Date, summary: FoodStatusSummary) {
        self.date = date
        expired = summary.expiredCount
        nearExpiry = summary.nearExpiryCount
        fresh = summary.freshCount
        upcomingExpiryCost = summary.upcomingExpiryCost
    }

    static let empty = StatusEntry(date: .now, summary: FoodStatusSummary(active: []))
}

struct StatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> StatusEntry {
        // 佔位不讀資料：系統會在載入前短暫顯示，讀取會拖慢首次呈現。
        StatusEntry(date: .now, summary: FoodStatusSummary(active: []))
    }

    func getSnapshot(in context: Context, completion: @escaping (StatusEntry) -> Void) {
        completion(StatusEntry(date: .now, summary: WidgetStore.loadSummary()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatusEntry>) -> Void) {
        let now = Date.now
        let entry = StatusEntry(date: now, summary: WidgetStore.loadSummary(today: now))
        // 效期是日期的函式——同一筆資料跨過午夜就換桶，因此刷新點設在次日零時。
        // 資料變動時另由 app 主動要求重載（WidgetCenter.reloadAllTimelines）。
        completion(Timeline(entries: [entry], policy: .after(DayBoundary.next(after: now))))
    }
}

struct FoodEntropyWidgetEntryView: View {
    var entry: StatusEntry

    var body: some View {
        // 內距是容器的責任：app 內由 List 的 row insets 提供，Widget 沒有 List，
        // 故在此自行補上（與「Section 容器留在 HomeView」同一個原則）。
        VStack(spacing: 2) {
            StatusChartView(
                expired: entry.expired,
                nearExpiry: entry.nearExpiry,
                fresh: entry.fresh,
                upcomingExpiryCost: entry.upcomingExpiryCost
            )
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }
}

@main
struct FoodEntropyWidget: Widget {
    private let kind = "FoodEntropyStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatusProvider()) { entry in
            FoodEntropyWidgetEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        // 系統預設四周各約 16pt，扣掉後高度不足以容納環形圖與金額行；
        // 停用後由 EntryView 自行控制較緊湊的內距。
        .contentMarginsDisabled()
        .configurationDisplayName("Expiry Overview")
        .description("See at a glance how much food is about to expire.")
        .supportedFamilies([.systemMedium])
    }
}
