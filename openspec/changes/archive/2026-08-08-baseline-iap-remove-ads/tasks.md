## 1. Baseline 文件化

- [x] 1.1 從 `StoreManager.refreshEntitlements()` 寫出 requirement「Ownership is derived from StoreKit entitlements and never stored locally」；驗證：該方法同時檢查 `transaction.productID == removeAdsProductID` 與 `transaction.revocationDate == nil`；且 `grep -rn "adsRemoved" Sources` 無任何 `UserDefaults` 或持久化寫入路徑。
- [x] 1.2 從 `start()` 與 `listenForTransactionUpdates()` 寫出 requirement「The app reconciles at launch and listens for transaction updates」；驗證：`start()` 依序呼叫監聽註冊、`refreshProducts()`、`refreshEntitlements()`，且監聽以 `guard updatesTask == nil` 防止重複註冊；`SceneDelegate` 在啟動時呼叫 `store.start()`。
- [x] 1.3 從 `purchaseRemoveAds()` 的 result 分支寫出 requirement「A purchase counts only when verified, and must be finished」；驗證：`.success` 分支仍以 `case let .verified(transaction)` 驗證，接著 `await transaction.finish()` 與 `await refreshEntitlements()`，`.userCancelled` 與 `.pending` 皆回傳 `false`。
- [x] 1.4 從 `restore()` 與 `SettingsViewModel.restoreDidTap` 寫出 requirement「A restore control is offered even though entitlements usually make it unnecessary」；驗證：`restore()` 呼叫 `AppStore.sync()` 後 `refreshEntitlements()`，設定畫面存在對應的 `restoreDidTap` 動作。
- [x] 1.5 從 `SettingsViewModel` 的 `purchaseInFlight` 旗標寫出 requirement「Purchase and restore cannot be triggered concurrently」；驗證：`removeAdsDidTap` 與 `restoreDidTap` 兩個分支皆以 `guard !state.purchaseInFlight` 開頭，並共用同一旗標。
- [x] 1.6 從 `removeAdsProduct` 為 optional 與 `purchaseRemoveAds()` 的 `guard let product` 寫出 requirement「Purchase is unavailable when the product could not be loaded」；驗證：無商品時 `purchaseRemoveAds()` 回傳 `false`，且 `SettingsViewModel.onAppear` 以 `store.removeAdsProduct?.displayPrice ?? ""` 取價格文字。

## 2. 收尾

- [x] 2.1 執行 `spectra validate baseline-iap-remove-ads`；驗證：指令回傳成功、無 error。
- [x] 2.2 archive 後補上 `openspec/specs/iap-remove-ads/spec.md` 的 `## Purpose` 段；驗證：`grep -c "TBD" openspec/specs/iap-remove-ads/spec.md` 為 0。
