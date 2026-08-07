## 1. Baseline 文件化

- [x] 1.1 從 `SettingsView.body` 的三個 Section view 寫出 requirement「Settings is organised into purchase, sync and notifications, and about」；驗證：`PurchaseSection`、`SyncSection`、`AboutSection` 依序組成畫面，各自以巢狀 `Action` 列舉回報意圖。
- [x] 1.2 從 `PurchaseSection` 的 `adsRemoved` / `inFlight` 分支與 `SettingsViewModel` 的購買流程寫出 requirement「The purchase row reflects owned, available, and in-progress states」；驗證：已購買分支顯示 `Label("已購買", systemImage: "checkmark.circle.fill")` 而非按鈕；`inFlight` 為真時以 `ProgressView()` 取代價格且購買與還原按鈕皆帶 `.disabled(inFlight)`；`showPurchaseError` 對應「購買失敗」alert。
- [x] 1.3 從 `state.removeAdsPriceText` 的來源寫出 requirement「The price comes from the store and is not formatted by the app」；驗證：`SettingsViewModel.onAppear` 以 `store.removeAdsProduct?.displayPrice ?? ""` 取值，`Sources` 內無自行組貨幣字串的邏輯。
- [x] 1.4 從 `PurchaseSection` 的 footer 三元式寫出 requirement「The section's explanatory text changes with ownership」；驗證：`SettingsView.swift:115` 依 `adsRemoved` 在致謝文案與一次性購買說明之間切換。
- [x] 1.5 從 `iCloudSyncToggled` 分支與「設定已變更」alert 寫出 requirement「Toggling iCloud sync immediately explains that a restart is needed」；驗證：該分支設 `state.showRestartNotice = true`，`SettingsView.swift:31–35` 綁定對應 alert 且內文說明下次開啟生效。
- [x] 1.6 從 `notificationDidTap` 的三態分流與 `notificationStatusText` 寫出 requirement「The notification row shows the current permission state and routes accordingly」；驗證：狀態文字三分支為「已開啟」／「已關閉」／「未設定」且皆走 `String(localized:)`；`notDetermined` 呼叫 `requestAuthorizationIfNeeded()`，`denied` 與 `authorized` 發出 `onRoute?(.openNotificationSettings)`。
- [x] 1.7 從 `privacyPolicyDidTap`、`privacyPolicyURL` 常數與 `AboutSection` 的版本列寫出 requirement「The privacy policy opens inside the app and the version is shown」；驗證：URL 為型別層級常數且與 App Store Connect 的 Privacy Policy URL 相同（`https://shinrenpan.github.io/FoodEntropy/privacy`）；`appVersionText` 由 `CFBundleShortVersionString` 與 `CFBundleVersion` 組成。
- [x] 1.8 從 `onAppear` 分支載入的五項狀態寫出 requirement「All displayed state is reloaded each time the screen appears」；驗證：該分支依序設定 `iCloudSyncEnabled`、`versionText`、`notificationStatus`、`adsRemoved`、`removeAdsPriceText`。

## 2. 收尾

- [x] 2.1 執行 `spectra validate baseline-settings-ui`；驗證：指令回傳成功、無 error。
- [x] 2.2 archive 後補上 `openspec/specs/settings-ui/spec.md` 的 `## Purpose` 段；驗證：`grep -c "TBD" openspec/specs/settings-ui/spec.md` 為 0。
- [x] 2.3 更新 `openspec/specs/README.md`，將 Screens 三個 capability 標為已補回；驗證：Screens 段落無殘留「⬜ 待補」。
