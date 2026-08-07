## 1. Baseline 文件化

- [x] 1.1 從 `AdConfig.makeRequest()` 的 `npa=1` extras 與 `project.yml` 的 Info.plist 設定寫出 requirement「Ad requests are non-personalised and the app never asks for tracking permission」；驗證：`grep -rn "ATTrackingManager\|NSUserTrackingUsageDescription" Sources project.yml` 僅命中 `project.yml:76` 說明「故不需 NSUserTrackingUsageDescription」的註解，無實際 API 呼叫或 plist 鍵；且 `makeRequest()` 註冊 `["npa": "1"]`。
- [x] 1.2 從 `AdConfig.homeBannerUnitID` 的編譯條件寫出 requirement「Development builds must not use the production ad unit」；驗證：測試單元 `ca-app-pub-3940256099942544/2934735716` 位於 `#if DEBUG`、正式單元位於 `#else`。
- [x] 1.3 從 `AdSlotView` 的三態與 `collapsed` 計算寫出 requirement「The ad slot reserves space while loading and collapses only on failure」；驗證：`collapsed` 僅在 `state == .failed` 為真，且 `frame(height:)`、`padding(.vertical:)`、`background(...opacity:)` 三者皆依 `collapsed` 歸零。
- [x] 1.4 從 `AdSlotView` 的 `background` 與 `overlay` 寫出 requirement「The ad slot is opaque and labelled once an ad is present」；驗證：背景為 `Color(.systemGroupedBackground)` 且非收合時 opacity 為 1；「廣告」標示的 `overlay` 條件為 `state == .loaded`。
- [x] 1.5 從 `HomeView` 的 `if !viewModel.state.adsRemoved` 條件與 `AdSlotView` 的內容寫出 requirement「Purchasing ad removal prevents the slot from being created at all」；驗證：`HomeView.swift:37` 以該條件包裹 `AdSlotView()`，且 `grep -n "adsRemoved\|StoreManager" Sources/Core/Ad/*.swift` 僅命中 `AdSlotView.swift:7` 說明此分工的註解，無實際程式碼相依。
- [x] 1.6 從 `02-architecture` §9 與 AdMob 的 app-ads.txt 驗證機制寫出 requirement「app-ads.txt verification depends on the store listing's marketing URL」；驗證：`curl -s https://shinrenpan.github.io/app-ads.txt` 回傳含本 app publisher ID（`pub-9003896396180654`）的內容且 HTTP 200；App Store Connect 的行銷 URL 欄位現況為空，該欄位規範歸 `app-store-listing`。

## 2. 收尾

- [x] 2.1 執行 `spectra validate baseline-advertising`；驗證：指令回傳成功、無 error。
- [x] 2.2 archive 後補上 `openspec/specs/advertising/spec.md` 的 `## Purpose` 段；驗證：`grep -c "TBD" openspec/specs/advertising/spec.md` 為 0。
- [x] 2.3 更新 `openspec/specs/README.md` capability map，將本批六個 domain capability 標為已補回；驗證：檔案內 Domain 段落無殘留「⬜ 待補」。
