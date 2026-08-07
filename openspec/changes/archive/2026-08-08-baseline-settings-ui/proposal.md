## Summary

補回 v1.0.0 的設定畫面 baseline：購買區的三種狀態呈現與防重入、iCloud 開關與重啟提示、通知列的狀態顯示與三態分流、隱私權政策的 app 內開啟，以及版本資訊。無行為變更。

## Motivation

設定畫面本身邏輯不多，但它是三個 domain capability 的唯一使用者介面——`iap-remove-ads`、`icloud-sync`、`notification` 的所有使用者可控行為都在這裡。它們各自的規格描述的是機制，而「使用者實際看到什麼、能按什麼」只存在於這個畫面。

另外，`specs/03-screens/settings.md` 已經與實作脫節：該文件寫「v1 購買邏輯 stub、延後至里程碑 2」，但 v1.0.0 實際完整實作了 StoreKit 購買與還原；它描述的通知列行為是「非已開啟就導向系統設定」，實作則是三態分流（未設定時直接請求權限，已決定才導向系統設定）。實作的版本較好——對從未被詢問過的使用者，直接跳系統彈窗比把他丟到系統設定合理得多。baseline 依實作現況記錄。

## Proposed Solution

從 `Sources/Features/Settings/SettingsView.swift`、`SettingsViewModel.swift`、`SettingsViewModel+Models.swift` 與 `specs/03-screens/settings.md` 寫出 `settings-ui` capability spec，涵蓋：三個分區的組成、購買列的狀態呈現與進行中停用、還原入口、iCloud 開關與重啟提示、通知列的狀態文字與三態分流、隱私權政策的開啟方式、版本呈現，以及進入畫面時的狀態載入。

## Non-Goals

- 無行為變更。
- 不涵蓋購買與 entitlement 的推導機制，那屬 `iap-remove-ads`。
- 不涵蓋同步偏好的儲存與生效機制，那屬 `icloud-sync`。
- 不涵蓋通知的排程與權限狀態語意，那屬 `notification`。
- 不涵蓋離開 App 開啟系統設定的導航界線與 sheet 呈現機制，那屬 `navigation`。
- 不涵蓋隱私權政策網頁本身的內容。

## Capabilities

### New Capabilities

- `settings-ui`：設定畫面的三個分區、購買列狀態與防重入、還原入口、同步開關與重啟提示、通知列狀態與分流、隱私權政策與版本、進入時的狀態載入。

### Modified Capabilities

（無）

## Impact

- Affected specs: new `settings-ui`
- Affected code:
  - New: （無 —— 記錄既有程式碼）
  - Modified: （無）
  - Removed: （無）
  - Reference: `Sources/Features/Settings/SettingsView.swift`, `Sources/Features/Settings/SettingsViewModel.swift`, `Sources/Features/Settings/SettingsViewModel+Models.swift`, `Sources/Features/Settings/SettingsHostController.swift`, `specs/03-screens/settings.md`
