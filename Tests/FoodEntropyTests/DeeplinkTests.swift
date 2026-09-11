import Foundation
import Testing
@testable import FoodEntropy

// 集中式 Deeplink 的解析與產生（見 navigation）。
struct DeeplinkTests {

    @Test("foodentropy://home 解析為 .home")
    func parsesHome() {
        #expect(Deeplink(url: URL(string: "foodentropy://home")!) == .home)
    }

    @Test("foodentropy://item/<uuid> 解析為該筆食材")
    func parsesFoodItem() {
        let id = UUID()
        let url = URL(string: "foodentropy://item/\(id.uuidString)")!
        #expect(Deeplink(url: url) == .foodItem(id))
    }

    @Test("item 後面不是合法 UUID 時不解析")
    func rejectsMalformedItemIdentifier() {
        #expect(Deeplink(url: URL(string: "foodentropy://item/not-a-uuid")!) == nil)
        #expect(Deeplink(url: URL(string: "foodentropy://item")!) == nil)
    }

    @Test("其他 scheme 一律不解析")
    func rejectsForeignScheme() {
        #expect(Deeplink(url: URL(string: "https://item/\(UUID().uuidString)")!) == nil)
    }

    /// Intent 要把目標轉回 URL 再走既有的 URL 進入點，往返必須一致。
    @Test("產生的 URL 能被自己解析回同一個目標")
    func roundTrips() {
        let id = UUID()
        let deeplink = Deeplink.foodItem(id)
        let url = try! #require(deeplink.url)
        #expect(Deeplink(url: url) == deeplink)
        #expect(Deeplink(url: try! #require(Deeplink.home.url)) == .home)
    }
}
