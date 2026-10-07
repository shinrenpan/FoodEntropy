## Why

iPhone Duo 內螢幕不理會 app 宣告的直立鎖定：只要內螢幕轉成橫向（全開或半開），食熵就以橫向全螢幕執行，首頁卡牌被拉成將近 951pt 寬，文字與數字分在兩端、中間大片空白。用 Xcode 27.1 重新建置後這個畫面就會出現在 Duo 使用者面前，所以要在送審 Duo 版之前處理。

## What Changes

- 首頁所在畫面在「容器寬大於高」時改為兩欄：設定在左（leading）、卡牌首頁在右（trailing）；其餘情況（一般 iPhone、Duo 外螢幕、Duo 內螢幕直向）維持只顯示首頁。依 Apple Mail 的模型，闔上時看到的內容翻開後留在 trailing 側。
- 兩欄依折線（`reservedRegions(kind: .division)`）分界：半開時兩欄分別停在折線兩側、讓出折線寬度；平放全開時分界對準折線中央。
- 設定已並排顯示時，首頁導覽列不顯示設定按鈕；從首頁推入的設定頁在畫面變成兩欄時自動退回首頁，避免同時出現兩份設定。
- 包進 SwiftUI 的 AdMob `BannerView` 改為由外層決定寬度（實作 `sizeThatFits`），不採用 SDK 自報的尺寸。不加時，app 執行中從單欄轉兩欄會讓廣告溢出、蓋進鄰欄（GoogleMobileAds 13.7.0 與 13.11.0 皆實測重現）。
- 移除廣告的 entitlement 改變時，首頁與設定頁都即時更新，不需要返回或重新出現（設定常駐在旁時不會再觸發 onAppear）。
- 設定頁回到前景時重讀狀態（通知權限等），不只在出現時讀。
- GoogleMobileAds 最低版本提高到 13.11.0（官方正式支援 iPhone Duo 的版本）。
- 平台方向規格修正：一般 iPhone 與 Duo 外螢幕維持只支援直立（外螢幕遵守宣告，已實測）；Duo 內螢幕不理會宣告，由版面依可用空間決定。

## Non-Goals

- 不改用 SwiftUI `ArrangementView`：`.split` 沒有指定 primary 落在哪一側的 API，卡牌只能在左（27.1 SDK 比對與實測）。
- 不改用 `UISplitViewController`／`NavigationSplitView`：column 樣式收合時把首頁推到設定的堆疊上，首頁多出返回鈕、堆疊根變成設定；classic delegate 寫法在 iOS 27 SDK 斷言失敗（實測）。
- 這一版不改用 `UIArrangementViewController` 容器：它會讓所有 iOS 27.1 iPhone 經過容器的收合與按鈕轉接路徑，而 27.1 模擬器 runtime 只支援 Duo、目前無法驗證一般 iPhone。等一般 iPhone 能測 27.1 時另開 change。
- 不處理 Duo 內螢幕直向半開時的橫向折線：直向只顯示首頁，可捲動內容依 Apple 原則不需避開折線。
- 不處理分桶清單 sheet 開著時 deeplink 被推到 sheet 底下的既有缺陷：與 Duo 無關，另開修正 change。
- 不開啟多 scene（`UIApplicationSupportsMultipleScenes` 維持 false）。
- 不重新設計左欄內容：左欄就是既有的設定頁。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `app-shell`: 平台方向要求改為「一般 iPhone 與 Duo 外螢幕只支援直立；Duo 內螢幕依可用空間排版」。
- `home-ui`: 新增寬容器時設定與首頁並排的要求（含折線分界、並排時不顯示設定按鈕、推入的設定頁在變寬時退回）；修改「從導覽列進入設定」的要求以涵蓋並排情況。
- `settings-ui`: 狀態重讀從「每次出現」擴大為「出現、回到前景、entitlement 改變時」。
- `advertising`: 新增「廣告的寬度由版面決定，不由 SDK 自報尺寸決定」。
- `iap-remove-ads`: 新增 entitlement 改變時對所有已顯示畫面廣播的要求。

## Impact

- 程式碼：Sources/Features/Home/HomeRootView.swift（新增）、Sources/Features/Home/HomeHostController.swift、Sources/Features/Home/HomeView.swift、Sources/Features/Settings/SettingsHostController.swift、Sources/Features/Settings/SettingsView.swift、Sources/Core/Ad/BannerAdView.swift、Sources/Core/Store/StoreManager.swift
- 設定：project.yml（GoogleMobileAds 最低版本 13.11.0）
- 文件：CLAUDE.md 與 openspec/config.yaml 的「portrait-locked」平台描述
- 依賴：GoogleMobileAds 13.11.0
- 已知架構債（MVVMC，2026-10-07）：`SettingsHostController.handle(_:from:)`（static，供首頁代處理並排設定的導航）與 `SettingsView.isEmbedded`。之後改用 `UIArrangementViewController` 容器時一併移除；解法已由 MVVMC Experiments/PaneProbe 驗證。
- 參考實作：branch experiment/duo-hstack-fold（ec0069f），Duo 模擬器整圈驗證通過。
