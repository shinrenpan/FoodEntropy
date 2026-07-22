import Foundation

// 集中式路由（mvvmc-navigation）。所有 URL / Push 解析只住這一檔。
// v1 僅需「通知點擊 → 首頁 Tab」（01-navigation §7），故只有 .home。
// 未來若新增 present-style 目標（detail 頁），再補 makeHostController() 分支。
enum Deeplink {
    case home
}

// MARK: - URL Parsing（URL Scheme 與 Push payload 共用）

extension Deeplink {
    init?(url: URL) {
        guard url.scheme == "foodentropy" else { return nil }
        switch url.host {
        case "home":
            self = .home
        default:
            return nil
        }
    }
}
