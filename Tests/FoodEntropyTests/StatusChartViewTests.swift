import Foundation
import Testing
@testable import FoodEntropy

// 共用呈現元件的資料組成。繪製本身不測（無 UI 測試依賴），
// 但「三桶的順序與數量」是 Widget 與首頁必須一致的部分，值得釘住。
@MainActor
struct StatusChartViewTests {
    @Test
    func `三桶依已過期、近期、期限內排序`() {
        let view = StatusChartView(expired: 2, nearExpiry: 3, fresh: 5)
        #expect(view.slices.map(\.status) == [.expired, .nearExpiry, .fresh])
    }

    @Test
    func `各桶數量對應建構參數`() {
        let view = StatusChartView(expired: 2, nearExpiry: 3, fresh: 5)
        #expect(view.slices.map(\.count) == [2, 3, 5])
    }

    @Test
    func `總數為三桶相加`() {
        let view = StatusChartView(expired: 2, nearExpiry: 3, fresh: 5)
        #expect(view.total == 10)
    }

    @Test
    func `三桶皆為零時總數為零`() {
        let view = StatusChartView(expired: 0, nearExpiry: 0, fresh: 0)
        #expect(view.total == 0)
    }

    @Test
    func `僅單一桶有項目時總數與該桶相同`() {
        let view = StatusChartView(expired: 0, nearExpiry: 4, fresh: 0)
        #expect(view.total == 4)
        #expect(view.slices.map(\.count) == [0, 4, 0])
    }

    @Test
    func `未提供前瞻金額時預設為 nil`() {
        let view = StatusChartView(expired: 1, nearExpiry: 1, fresh: 1)
        #expect(view.upcomingExpiryCost == nil)
    }
}
