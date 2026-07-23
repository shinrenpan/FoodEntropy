import GoogleMobileAds

// 廣告設定集中處（02-architecture §9）。
// 決策：非個人化廣告、不跳 ATT（不追蹤、不存取 IDFA），全球上架、排除歐盟。
enum AdConfig {
    /// 首頁頂部 banner 廣告單元 ID。
    ///
    /// 開發階段一律用 **Google 官方測試單元**（用正式 ID 自我測試會違反政策、可能被停用）。
    /// ⚠️ 上架前：把 Release 分支換成 AdMob 後台建立的正式 banner 單元 ID（ca-app-pub-XXXX/ZZZZ），
    ///    並同步把 `project.yml` 的 `GADApplicationIdentifier` 換成正式 App ID。
    static var homeBannerUnitID: String {
        #if DEBUG
        "ca-app-pub-3940256099942544/2934735716"   // Google 官方測試 banner
        #else
        "ca-app-pub-3940256099942544/2934735716"   // ⚠️ 待換：正式 banner 單元 ID
        #endif
    }

    /// 建立「非個人化」廣告請求（npa=1）。不追蹤、不需 ATT。
    static func makeRequest() -> Request {
        let request = Request()
        let extras = Extras()
        extras.additionalParameters = ["npa": "1"]
        request.register(extras)
        return request
    }
}
