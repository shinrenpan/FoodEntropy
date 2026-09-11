import Foundation

// 集中式路由（mvvmc-navigation）。所有 URL / Push 解析只住這一檔。
enum Deeplink: Equatable {
    case home
    /// 單筆食材的 detail（編輯 Form）。由 Spotlight 點擊結果與 Siri 的
    /// 「開啟某食材」共用——兩者都經由 `OpenFoodItemIntent` 走到這裡。
    case foodItem(UUID)
}

// MARK: - URL Parsing（URL Scheme 與 Push payload 共用）

extension Deeplink {
    private static let scheme = "foodentropy"

    init?(url: URL) {
        guard url.scheme == Self.scheme else { return nil }
        switch url.host {
        case "home":
            self = .home
        case "item":
            // foodentropy://item/<uuid>
            let identifier = url.pathComponents.first { $0 != "/" }
            guard let identifier, let id = UUID(uuidString: identifier) else { return nil }
            self = .foodItem(id)
        default:
            return nil
        }
    }

    /// 產生對應的 URL。`OpenFoodItemIntent` 用它把目標交回既有的 URL 進入點，
    /// 而不是另闢一條導航路徑——集中式 Deeplink 的意義就在只有一條路。
    var url: URL? {
        switch self {
        case .home:
            URL(string: "\(Self.scheme)://home")
        case let .foodItem(id):
            URL(string: "\(Self.scheme)://item/\(id.uuidString)")
        }
    }
}
