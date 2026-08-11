## Why

FoodEntropy 目前只有 iOS 版。MVVMC 架構的分層——`@Model` → `SwiftDataManager`（`toDomain()`）→ ViewModel → State → View——本身沒有綁定 Apple 平台：ViewModel 以上只吃 Domain Model，唯一碰 SwiftData 的地方是 `SwiftDataManager`。既有的 `mvvmc-skip` 規範也已在別的專案驗證過「iOS 架構零改動就能跨到 Android」。這個 change 要驗證的是：那個結論在一個**真的有持久化、有廣告、有圖表**的 app 上是否仍然成立。

現在做的理由是 v1.1.0 剛上架、iOS 側處於穩定狀態，沒有進行中的功能開發會與移植互相干擾。

> **本 change 為事先提出的規劃，無排程。** 它記錄的是「若要跨平台，該怎麼做、風險在哪」，不是待辦事項。除非作者主動提起，否則不需要在對話中提醒或建議動工。

## What Changes

- 導入 Skip 工具鏈，讓同一份 Swift 原始碼同時產出 iOS 與 Android app。
- **iOS 行為完全不變**——這是驗收標準，不是順帶檢查。所有平台差異一律以 `#if !SKIP` / `#else` 表達，不重構既有分層。
- Android 版的持久層以 SkipSQL 手寫 CRUD 實作，回傳同一組 Domain Model；ViewModel 以上不修改。
- Android 版自行以 Kotlin 互操作橋接 Google Mobile Ads Android SDK。
- Android 版的到期通知改以 Android 的排程與通知機制實作，行為對齊 iOS（到期當天 09:00、一項一則）。
- 首頁的甜甜圈與長條圖在 Android 以基本圖形重繪，Swift Charts 僅保留於 iOS 分支。
- 影像壓縮在 Android 改用平台原生點陣圖 API，壓縮參數與 iOS 相同。
- **BREAKING（僅限 Android）**：Android 版不提供移除廣告的內購，亦不提供 iCloud 同步。兩者在 Android 沒有等價物，相關程式碼整檔以 `#if !SKIP` 隔離。

## Capabilities

### New Capabilities

- `cross-platform`: 規範 Skip 跨平台的界線——iOS 零改動原則、平台差異一律以條件編譯表達而非重構、哪些行為必須兩邊一致、哪些功能允許只存在於單一平台，以及各層（M/VM/V/C）在 Android 側的對應形式。

### Modified Capabilities

- `persistence`: 現行 requirement 將持久層的契約直接寫成 SwiftData 的約束（CloudKit-safe 的 `@Model`、`ModelContainer` 三層降級）。需改為「契約以 Domain Model 與 `toDomain()` 邊界定義，SwiftData 是 iOS 的實作選擇之一」，使同一份契約能涵蓋 Android 的 SkipSQL 實作。

## Impact

- Affected specs: `cross-platform`（新增）、`persistence`（修改）
- Affected code:
  - New:
    - `Sources/Core/Persistence/SQLiteFoodStore.swift`
    - `Sources/Core/Image/ImageCompressor+Android.swift`
    - `Sources/Core/Ad/BannerAdView+Android.swift`
    - `Sources/Core/Notification/NotificationService+Android.swift`
    - `Sources/Features/Home/HomeChartsFallback.swift`
    - `Android/` — Gradle 專案與 Kotlin 橋接原始碼
  - Modified:
    - `Sources/Core/Persistence/SwiftDataManager.swift`
    - `Sources/Core/Persistence/FoodItemEntity.swift`
    - `Sources/Core/Notification/NotificationService.swift`
    - `Sources/Core/Image/ImageCompressor.swift`
    - `Sources/Core/Ad/BannerAdView.swift`
    - `Sources/Core/Ad/AdSlotView.swift`
    - `Sources/Core/Store/StoreManager.swift`
    - `Sources/App/AppDelegate.swift`
    - `Sources/App/SceneDelegate.swift`
    - `Sources/App/AppRouter.swift`
    - `Sources/App/Deeplink.swift`
    - `Sources/Features/Home/HomeView.swift`
    - `Sources/Features/Home/HomeViewModel.swift`
    - `Sources/Features/Home/HomeHostController.swift`
    - `Sources/Features/FoodForm/FoodFormView.swift`
    - `Sources/Features/FoodForm/FoodFormViewModel.swift`
    - `Sources/Features/FoodForm/FoodFormHostController.swift`
    - `Sources/Features/Settings/SettingsView.swift`
    - `Sources/Features/Settings/SettingsViewModel.swift`
    - `Sources/Features/Settings/SettingsHostController.swift`
    - `project.yml`
  - Removed:（無）
- Dependencies: 新增 Skip 工具鏈與 Android 建置環境（Gradle、Android SDK）。Android 側需引入 Google Mobile Ads Android SDK——這是 constitution「第三方依賴僅限 Google AdMob」的同一套廣告服務在另一平台的 SDK，不構成新的第三方依賴類別。
