## Summary

補回 v1.0.0 的在地化 baseline：以繁體中文為原文語言、英文為翻譯目標的 String Catalog 慣例、Info.plist 權限描述的在地化、日期與金額交由系統格式化，以及「哪些字串刻意不翻譯」的界線。無行為變更。

## Motivation

「不硬編字串」是憲章鐵則之一，但憲章沒有回答一個每次寫程式都會遇到的問題：**哪些字串不該進 String Catalog**。

目前程式碼裡有一批中文字串刻意留在原地——`assertionFailure` 與 `fatalError` 的診斷訊息、DEBUG 模式下的 mock 食材名稱、deeplink 的 URL scheme。它們都含中文或看起來像文案，但都不面向使用者：診斷訊息只有開發者在 Xcode 裡看得到，翻譯它們只會讓錯誤更難搜尋；mock 資料在 Release 根本不存在。若沒有明確界線，這些會在某次「補齊在地化」的清理中被錯誤地納入，或者反過來，真正的使用者文案被誤判為「內部字串」而漏掉。

第二件事是**格式化的歸屬**：金額直接用 StoreKit 的顯示價格、日期用系統格式化，不自行組字串。這讓地區與貨幣的正確性由系統負責，而不是散落在各處的手工格式。

## Proposed Solution

從 `Sources/Resources/Localizable.xcstrings`、`Sources/Resources/InfoPlist.xcstrings`、`project.yml` 的語系設定，以及程式碼中未在地化字串的實際分布，寫出 `localization` capability spec，涵蓋：原文語言與支援語言、面向使用者字串一律走 String Catalog、Info.plist 權限描述的在地化、格式化交由系統、使用者資料不翻譯，以及刻意不翻譯的三類字串。

## Non-Goals

- 無行為變更，不新增或修改任何翻譯。
- 不涵蓋發行區域與 App Store 線上文案，那屬 `app-store-listing`。
- 不涵蓋各畫面的具體文案內容，那屬各畫面自己的 capability。
- 不規範未來新增語言的流程——v1.0.0 支援繁體中文與英文兩種。

## Capabilities

### New Capabilities

- `localization`：String Catalog 慣例、原文語言與支援語言、Info.plist 在地化、格式化歸屬、不翻譯的界線。

### Modified Capabilities

（無）

## Impact

- Affected specs: new `localization`
- Affected code:
  - New: （無 —— 記錄既有程式碼）
  - Modified: （無）
  - Removed: （無）
  - Reference: `Sources/Resources/Localizable.xcstrings`, `Sources/Resources/InfoPlist.xcstrings`, `project.yml`, `specs/00-constitution.md`
