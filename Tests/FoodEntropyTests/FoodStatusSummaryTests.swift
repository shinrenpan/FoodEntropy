import Foundation
import Testing
@testable import FoodEntropy

// 首頁與 Widget 共用的分桶與金額計算。兩處顯示的數字必須相同，
// 因此邏輯只有這一份——這些測試釘住的是「相同」本身。
@MainActor
struct FoodStatusSummaryTests {
    private let today = Date(timeIntervalSince1970: 1_700_000_000)

    private func item(name: String, daysFromToday: Int, price: Double? = nil) -> FoodItem {
        FoodItem(
            id: UUID(),
            name: name,
            purchaseDate: today,
            expiryDate: Calendar.current.date(byAdding: .day, value: daysFromToday, to: today)!,
            status: .active,
            resolvedAt: nil,
            imageData: nil,
            createdAt: today,
            price: price
        )
    }

    @Test
    func `依效期分為三桶`() {
        let summary = FoodStatusSummary(
            active: [
                item(name: "過期", daysFromToday: -1),
                item(name: "今天到期", daysFromToday: 0),
                item(name: "三天內", daysFromToday: 3),
                item(name: "還很久", daysFromToday: 10),
            ],
            today: today
        )
        #expect(summary.expired.map(\.name) == ["過期"])
        #expect(summary.nearExpiry.map(\.name) == ["今天到期", "三天內"])
        #expect(summary.fresh.map(\.name) == ["還很久"])
    }

    @Test
    func `前瞻金額只加總近期到期者`() {
        let summary = FoodStatusSummary(
            active: [
                item(name: "過期但有價", daysFromToday: -1, price: 999),
                item(name: "近期A", daysFromToday: 1, price: 60),
                item(name: "近期B", daysFromToday: 2, price: 40),
                item(name: "新鮮但有價", daysFromToday: 10, price: 500),
            ],
            today: today
        )
        #expect(summary.upcomingExpiryCost == 100)
    }

    @Test
    func `近期到期者皆未填價格時金額為 nil`() {
        let summary = FoodStatusSummary(
            active: [item(name: "近期無價", daysFromToday: 1)],
            today: today
        )
        #expect(summary.upcomingExpiryCost == nil)
    }

    @Test
    func `僅部分近期項目有價格時只加總有價者`() {
        let summary = FoodStatusSummary(
            active: [
                item(name: "有價", daysFromToday: 1, price: 60),
                item(name: "無價", daysFromToday: 2),
            ],
            today: today
        )
        #expect(summary.upcomingExpiryCost == 60)
    }

    @Test
    func `沒有任何項目時三桶皆空且金額為 nil`() {
        let summary = FoodStatusSummary(active: [], today: today)
        #expect(summary.expired.isEmpty)
        #expect(summary.nearExpiry.isEmpty)
        #expect(summary.fresh.isEmpty)
        #expect(summary.upcomingExpiryCost == nil)
    }

    @Test
    func `計數與各桶陣列長度一致`() {
        let summary = FoodStatusSummary(
            active: [
                item(name: "過期", daysFromToday: -5),
                item(name: "近期", daysFromToday: 1),
                item(name: "新鮮1", daysFromToday: 8),
                item(name: "新鮮2", daysFromToday: 9),
            ],
            today: today
        )
        #expect(summary.expiredCount == 1)
        #expect(summary.nearExpiryCount == 1)
        #expect(summary.freshCount == 2)
    }
}
