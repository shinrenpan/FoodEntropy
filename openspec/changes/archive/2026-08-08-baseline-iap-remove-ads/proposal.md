## Summary

補回 v1.0.0 的「移除廣告」購買 baseline：以 StoreKit 的 entitlement 為唯一真相而不自存旗標、啟動時對帳與交易更新監聽、購買與還原流程的成功判定，以及退款撤銷的反映。無行為變更。

## Motivation

這是 app 內唯一的付費路徑，而它的正確性完全依賴一個決定：**`adsRemoved` 由 `Transaction.currentEntitlements` 推導，不在本機存任何已購買旗標**。

自存旗標是最直覺的做法，也是最容易出錯的：退款與撤銷不會回頭改寫本機旗標，使用者退了款卻仍然沒有廣告；而任何寫進 `UserDefaults` 的解鎖狀態都是可竄改的。以 entitlement 為準則讓這兩個問題同時消失——退款後 `currentEntitlements` 不再包含該筆，`adsRemoved` 自然轉回 false；換裝置時只要同一 Apple ID，StoreKit 自己認得，連 Restore 都不需要。

這個決定沒有寫成規格的風險是：後來的人為了「避免每次啟動都查 StoreKit」而加上本機快取，於是同時引入退款漏洞與可竄改的解鎖狀態。

另一個需要固定的是「還原購買」按鈕的定位：正常情況下它是多餘的（entitlement 自動生效），保留它是為了符合 Apple 的審核慣例——沒有 Restore 入口的非消耗型 IAP 會被退件。

## Proposed Solution

從 `Sources/Core/Store/StoreManager.swift` 與 `Sources/Features/Settings/SettingsViewModel.swift` 的購買／還原分支、`specs/02-architecture.md` §7 寫出 `iap-remove-ads` capability spec，涵蓋：entitlement 單一真相、啟動對帳與更新監聽、購買結果判定、還原流程、退款撤銷的反映、購買中的防重入，以及商品載入失敗時的行為。

## Non-Goals

- 無行為變更。
- 不涵蓋廣告本身的載入與呈現，那屬 `advertising`；本 capability 只規範它讀取的那個 entitlement 旗標。
- 不涵蓋設定畫面的版面與價格文案排版，那屬 `settings-ui`。
- 不涵蓋 `app-shell` 記錄的截圖模式（該模式直接注入已購買狀態，屬 shell 的 DEBUG 隔離範圍）。
- 不涵蓋 App Store Connect 上的商品設定與審核附註（開發者端作業，非 app 行為）。

## Capabilities

### New Capabilities

- `iap-remove-ads`：StoreKit 2 非消耗型購買、entitlement 單一真相、啟動對帳與交易更新監聽、購買與還原流程、退款撤銷反映、防重入。

### Modified Capabilities

（無）

## Impact

- Affected specs: new `iap-remove-ads`
- Affected code:
  - New: （無 —— 記錄既有程式碼）
  - Modified: （無）
  - Removed: （無）
  - Reference: `Sources/Core/Store/StoreManager.swift`, `Sources/Features/Settings/SettingsViewModel.swift`, `Sources/App/SceneDelegate.swift`, `FoodEntropy.storekit`, `specs/02-architecture.md`
