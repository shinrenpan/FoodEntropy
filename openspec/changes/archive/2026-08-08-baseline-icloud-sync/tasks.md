## 1. Baseline 文件化

- [x] 1.1 從 `AppPreferenceKey.iCloudSyncEnabled` 與 `SceneDelegate.makeManager()` 的 `defaults.bool(forKey:)` 寫出 requirement「iCloud sync is opt-in and defaults to off」；驗證：偏好以 `UserDefaults.bool(forKey:)` 讀取（未設定時為 `false`），且 `Sources` 內無首次啟動的同意詢問流程。
- [x] 1.2 從 `SettingsViewModel` 的 `iCloudSyncToggled` 分支與 `SceneDelegate` 的啟動時決定寫出 requirement「A change to the sync setting applies at the next launch」；驗證：該分支只寫入 `defaults` 並設 `state.showRestartNotice = true`，未重建任何 container。
- [x] 1.3 從 `SwiftDataManager.init` 的 `ModelConfiguration(cloudKitDatabase:)` 寫出 requirement「Both switch positions use the same local store」；驗證：兩種取值（`.automatic` / `.none`）共用同一 `ModelConfiguration` 建構路徑，未指定不同的 store URL。
- [x] 1.4 從 `02-architecture` §6 的「關→開」段落寫出 requirement「Enabling sync uploads existing data without custom migration code」；驗證：`Sources` 內無任何自訂資料上傳／搬移程式碼，全由 container 承擔。
- [x] 1.5 從 `02-architecture` §6 的「開→關」段落寫出 requirement「Disabling sync stops syncing without deleting the cloud copy」；驗證：`Sources` 內無任何刪除 CloudKit 記錄的呼叫。
- [x] 1.6 從 `FoodItemEntity.imageData` 的 `@Attribute(.externalStorage)` 寫出 requirement「Photos are covered by sync」；驗證：圖片存於 SwiftData 屬性而非 Documents 目錄——`grep -rn "documentsDirectory\|\.documentDirectory" Sources` 無結果。

## 2. 收尾

- [x] 2.1 執行 `spectra validate baseline-icloud-sync`；驗證：指令回傳成功、無 error。
- [x] 2.2 archive 後補上 `openspec/specs/icloud-sync/spec.md` 的 `## Purpose` 段；驗證：`grep -c "TBD" openspec/specs/icloud-sync/spec.md` 為 0。
