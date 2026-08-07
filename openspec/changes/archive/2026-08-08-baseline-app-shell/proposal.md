## Summary

補回 v1.0.0 已上架的 app shell 規格 baseline：UIKit 生命週期進入點、SceneDelegate 作為唯一 composition root、store 建立的三層優雅降級、兩 Tab root、XcodeGen 專案生成，以及 MVVMC 資料夾慣例。無行為變更。

## Motivation

v1.0.0 在導入 Spectra 之前就已開發並上架，`openspec/specs/` 是空的。後續每個 change 的 proposal 都必須宣告它動到哪些 capability，沒有 baseline 就無處可指。

app-shell 是最底層的那一個：其他所有 capability 都跑在它建立的 window、tab bar 與注入的 manager 之上。它同時收納幾個「看起來像實作細節、其實是刻意決策」的東西——尤其是 `SwiftDataManager.makeResilient` 的三層降級（避免 store 建立失敗變成開機即崩的 crash loop），以及 `SCREENSHOT_MODE` 這類 DEBUG-only 逃生門必須留在 `#if DEBUG` 內的不變式。後者若被誰「順手清理」拿掉編譯條件，等同讓任何人用環境變數白拿「移除廣告」。這種只存在於程式碼註解、沒有規格保護的知識，正是 baseline 要固定下來的東西。

## Proposed Solution

從 `Sources/App/AppDelegate.swift`、`Sources/App/SceneDelegate.swift`、`project.yml` 與 `specs/00-constitution.md` 寫出 `app-shell` capability spec，涵蓋：UIKit 生命週期進入點、composition root 的注入方向、store 三層降級、兩 Tab + 每 Tab 自有 `UINavigationController` 的 root 結構、平台外框（iPhone only / portrait / iOS 26+ / dark mode）、XcodeGen 生成慣例、MVVMC 資料夾配置，以及 DEBUG-only 開關的隔離要求。

## Non-Goals

- 無行為變更，不動任何一行 Swift。
- 不涵蓋 `AppRouter` 的導航語意與 `Deeplink` 解析——那是 `navigation` capability 的範圍，本 capability 只負責它跑在其上的 window / tab bar 骨架。
- 不涵蓋 `SwiftDataManager` 的 schema、`toDomain()` 轉換與 CloudKit 約束（屬 `persistence`），本 capability 只規範「shell 在何時、以何種降級策略把它建出來」。
- 不涵蓋通知排程規則、IAP 購買流程、廣告載入行為本身——shell 只規範它們的啟動時機與注入方式。
- 不重述 mvvmc-* skills 的規則；資料夾慣例只記錄本專案實際採用的配置。

## Capabilities

### New Capabilities

- `app-shell`：UIKit 生命週期進入點、SceneDelegate composition root、store 三層降級、兩 Tab root 結構、平台外框、XcodeGen 生成與 MVVMC 資料夾慣例。

### Modified Capabilities

（無）

## Impact

- Affected specs: new `app-shell`
- Affected code:
  - New: （無 —— 記錄既有程式碼）
  - Modified: （無）
  - Removed: （無）
  - Reference: `Sources/App/AppDelegate.swift`, `Sources/App/SceneDelegate.swift`, `project.yml`, `specs/00-constitution.md`
