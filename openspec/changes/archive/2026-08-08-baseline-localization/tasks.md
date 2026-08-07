## 1. Baseline 文件化

- [x] 1.1 從 `Localizable.xcstrings` 的 `sourceLanguage` 與 `project.yml` 的語系設定寫出 requirement「Traditional Chinese is the source language and English is the translation」；驗證：`sourceLanguage` 為 `zh-Hant`；`developmentLanguage: zh-Hant`；`CFBundleLocalizations` 含 `zh-Hant` 與 `en`；96 個條目中缺英文翻譯者為 0。
- [x] 1.2 從 `SWIFT_EMIT_LOC_STRINGS` 設定與各層實際寫法寫出 requirement「User-facing strings reach the catalog, and the required syntax differs by layer」；驗證：`project.yml:43` 開啟該設定；ViewModel／Service／Manager 層的面向使用者字串皆以 `String(localized:)` 包裹；`Sources/Core/Domain/` 內無 `String(localized:)`，確認 Domain 不含文案。
- [x] 1.3 從 `InfoPlist.xcstrings` 的條目寫出 requirement「System-presented strings are localised in their own catalog」；驗證：該檔含 `CFBundleDisplayName`、`CFBundleName`、`NSCameraUsageDescription`、`NSPhotoLibraryUsageDescription` 四項，每項皆有 `en` 與 `zh-Hant`。
- [x] 1.4 從 `SettingsViewModel` 的 `displayPrice` 取值寫出 requirement「Currency and dates are formatted by the system, not assembled by the app」；驗證：`grep -rn "NumberFormatter\|currencyCode" Sources` 無結果，價格取自 `store.removeAdsProduct?.displayPrice`。
- [x] 1.5 從 `NotificationService.makeRequest` 的內文組成寫出 requirement「User-entered content is never translated」；驗證：通知內文以 `String(localized: "「\(food.name)」今天到期，記得處理。")` 組成——模板進 Catalog，食材名稱以插值原樣帶入。
- [x] 1.6 從程式碼中未在地化中文字串的實際分布寫出 requirement「Diagnostics, debug fixtures, and protocol strings stay out of the catalog」；驗證：非 View 層未包裹的中文字串僅出現在三類位置——`AppRouter` 與 `SwiftDataManager` 的 `assertionFailure` / `fatalError` 診斷訊息、`SceneDelegate` 中 `#if DEBUG` 內的 mock 食材名稱、以及 `NotificationService` 的 deeplink URL 字串。

## 2. 收尾

- [x] 2.1 執行 `spectra validate baseline-localization`；驗證：指令回傳成功、無 error。
- [x] 2.2 archive 後補上 `openspec/specs/localization/spec.md` 的 `## Purpose` 段；驗證：`grep -c "TBD" openspec/specs/localization/spec.md` 為 0。
