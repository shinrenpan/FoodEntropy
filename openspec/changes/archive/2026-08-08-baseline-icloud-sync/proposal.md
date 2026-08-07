## Summary

補回 v1.0.0 的 iCloud 同步 baseline：opt-in 且預設關閉的開關、變更後於下次啟動生效而非執行期熱切換、開關兩個方向皆指向同一本機 store，以及關閉同步不刪除雲端副本的語意。無行為變更。

## Motivation

這個開關的每一個設計都是刻意違反直覺的：

- **預設關閉**，即使同步對使用者有利。理由是不在未經同意的情況下把使用者的食材紀錄與照片上傳到任何地方——預設關、使用者主動開，本身就是同意行為，因此也不需要首次啟動的同意詢問，保住了「無 Onboarding」。
- **不做執行期熱切換**，切換後要重開 app 才生效。這在使用者眼中像是未完成的功能，但它換來的是不需要在執行期抽換 `ModelContainer`——那是最容易產生資料遺失與 context 失效的操作。
- **關閉同步不刪除雲端資料**。「關閉」的語意是停止同步，不是刪除備份；再打開會自動合併接回。

這些決定若沒有規格保護，很容易被後來的人當成缺陷「修好」——把預設改成開、加上熱切換、或在關閉時順手清雲端。

## Proposed Solution

從 `Sources/Core/AppPreferences.swift`、`SwiftDataManager.init(cloudKitEnabled:inMemory:)`、`SceneDelegate.makeManager()`、`SettingsViewModel` 的 `iCloudSyncToggled` 分支與 `specs/02-architecture.md` §6 寫出 `icloud-sync` capability spec，涵蓋：偏好的儲存與預設值、生效時機、雙向切換的資料語意、圖片一併同步，以及與 CloudKit-safe schema 的依存關係。

## Non-Goals

- 無行為變更。
- 不涵蓋 schema 的 CloudKit-safe 約束本身，那屬 `persistence`；本 capability 只說明它為何是這個開關能存在的前提。
- 不涵蓋 CloudKit 容器建立失敗時的降級，那屬 `app-shell`。
- 不涵蓋設定畫面的版面與文案，那屬 `settings-ui`。
- 不涵蓋 CloudKit Production schema 的部署流程（開發者端作業，非 app 行為）。

## Capabilities

### New Capabilities

- `icloud-sync`：opt-in 開關的儲存與預設、下次啟動生效的語意、雙向切換的資料處置、圖片同步範圍。

### Modified Capabilities

（無）

## Impact

- Affected specs: new `icloud-sync`
- Affected code:
  - New: （無 —— 記錄既有程式碼）
  - Modified: （無）
  - Removed: （無）
  - Reference: `Sources/Core/AppPreferences.swift`, `Sources/Core/Persistence/SwiftDataManager.swift`, `Sources/App/SceneDelegate.swift`, `Sources/Features/Settings/SettingsViewModel.swift`, `specs/02-architecture.md`
