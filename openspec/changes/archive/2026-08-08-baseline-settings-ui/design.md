## Context

設定是 app 的第二個也是最後一個 Tab，內容分三區：購買、同步與通知、關於。它不持有任何自己的資料——所有狀態都來自其他 capability（entitlement、偏好、系統權限、bundle 版本），畫面只負責呈現與轉發使用者的意圖。

## Goals / Non-Goals

**Goals:**
- 記錄購買列在三種狀態下的呈現與防重入。
- 記錄 iCloud 開關的即時提示。
- 記錄通知列的三態分流，特別是「未設定」與「已決定」的不同去向。
- 記錄狀態載入的時機。

**Non-Goals:**
- 無行為變更。
- 不涵蓋 `iap-remove-ads`、`icloud-sync`、`notification` 各自的機制，以及 `navigation` 的呈現方式。

## Decisions

### 購買列依 entitlement 呈現三種狀態

已購買時顯示帶勾的「已購買」標記且不可點；未購買時顯示價格與可點的購買列；進行中時以進度指示取代價格並停用購買與還原兩者。理由：三種狀態各自需要不同的可操作性，用同一列切換外觀比分成多列清楚。進行中停用兩個按鈕是因為它們共用同一個進行中旗標（見 `iap-remove-ads`），避免使用者在購買途中又觸發還原。

價格文字來自 StoreKit 的顯示價格，未載入時為空——不自行組字串或硬編幣別，因為顯示價格已依使用者的地區與貨幣格式化。

### 區塊 footer 依購買狀態改寫

未購買時 footer 說明這是一次性購買、永久移除首頁橫幅；已購買時改為致謝與確認。理由：footer 是這一區的說明文字，購買前後使用者需要知道的事不同——購買前需要知道買的是什麼，購買後需要確認它已生效。

### iCloud 開關切換後立即以提示告知需重啟

切換開關後彈出提示說明將於下次開啟 app 後生效。理由：這是 `icloud-sync` 的「下次啟動生效」設計對使用者唯一的可見說明。沒有它，使用者切換後去其他裝置檢查、發現沒動靜，會認為功能故障。

### 通知列顯示目前狀態，並依狀態分流去向

列上顯示「已開啟」／「已關閉」／「未設定」三種狀態文字。點擊時：未設定 → 直接請求權限（跳系統彈窗）；已開啟或已關閉 → 開啟系統設定。理由：對從未被詢問過的使用者，直接跳系統彈窗是最短路徑；而權限一旦決定，app 內的請求就不會再顯示彈窗，此時唯一能改變狀態的地方是系統設定。若對已決定的使用者仍呼叫請求，畫面上會像「按了沒反應」。

這也是通知權限被拒後的引導入口：使用者在首次儲存時拒絕，之後可在這裡看到「已關閉」並一鍵前往開啟。

### 版本顯示 version 與 build

從 bundle 讀取版本號與建置號，組成唯讀文字。理由：使用者回報問題時需要能說出版本；build number 則讓 TestFlight 與正式版可區分。

### 進入畫面時一次載入全部狀態

畫面出現時讀取偏好、系統權限狀態、entitlement、商品價格與版本。理由：這些狀態全都可能在畫面不可見時改變——使用者可能去系統設定改了通知權限、在其他裝置完成購買、或退款生效。每次出現時重新載入，比嘗試訂閱各個來源簡單且不會遺漏。

## Implementation Contract

**Behavior (observable):**
- 設定分為購買、同步與通知、關於三區。
- 未購買時購買列顯示價格；點擊後進行中顯示進度指示，購買與還原皆不可點。
- 已購買時購買列顯示「已購買」標記且不可點，該區說明文字改為致謝。
- 購買失敗時出現提示。
- 切換 iCloud 開關後立即出現「將於下次開啟 App 後生效」的提示。
- 通知列右側顯示「已開啟」／「已關閉」／「未設定」。
- 通知狀態為「未設定」時點擊該列，出現系統權限彈窗。
- 通知狀態為「已開啟」或「已關閉」時點擊該列，前往系統設定。
- 點擊隱私權政策在 app 內開啟網頁，可下拉關閉並回到設定。
- 關於區顯示版本與建置號。
- 離開設定再回來時，上述狀態皆為最新。

**Interface / data shape:**
- `SettingsViewModel`：`@Observable @MainActor`；`doAction(_:)` 單一進入點。
- `State`：`iCloudSyncEnabled`、`notificationStatus`、`versionText`、`showRestartNotice`、`adsRemoved`、`removeAdsPriceText`、`purchaseInFlight`、`showPurchaseError`。
- `ViewAction`：`onAppear`、`removeAdsDidTap`、`restoreDidTap`、`iCloudSyncToggled(Bool)`、`notificationDidTap`、`privacyPolicyDidTap`。
- `Router`：`openNotificationSettings`、`openPrivacyPolicy(URL)`。
- 隱私權政策 URL 為型別層級常數，與填入 App Store Connect 的同一個。
- 畫面拆為三個巢狀 Section view，各自以 `Action` 列舉回報意圖。

**Acceptance criteria:**
- 購買與還原按鈕在 `purchaseInFlight` 為真時皆停用。
- 已購買狀態下不呈現可點的購買按鈕。
- 價格文字直接取自商品的顯示價格，無自行格式化或硬編幣別。
- `notificationDidTap` 對 `notDetermined` 呼叫權限請求，對其餘兩態發出開啟系統設定的路由。
- `iCloudSyncToggled` 設定 `showRestartNotice`。
- 所有面向使用者的字串皆走 String Catalog。

**Scope boundaries:**
- In scope：三區組成、購買列狀態與防重入、還原入口、同步開關與提示、通知列狀態與分流、隱私權政策入口、版本顯示、狀態載入時機。
- Out of scope：購買與 entitlement 機制（`iap-remove-ads`）、同步偏好與生效（`icloud-sync`）、排程與權限語意（`notification`）、離開 App 與 sheet 呈現（`navigation`）、隱私權政策網頁內容。

## Risks / Trade-offs

- [購買失敗只有單一提示文字] → 不區分網路錯誤、驗證失敗或其他原因，使用者無從判斷該重試還是該做別的事。
- [通知狀態只在畫面出現時更新] → 使用者從系統設定改完權限回到 app，若設定畫面未重新出現（例如它一直在前景），顯示的狀態會是舊的。
- [價格未載入時為空字串] → 購買列會顯示一個沒有價格的可點項目，使用者無從得知金額；點擊後 StoreKit 也無法發起購買（見 `iap-remove-ads`），形同無反應。
- [`specs/03-screens/settings.md` 與實作脫節] → 該文件仍描述 v1 的 stub 版本與較舊的通知列行為。本 baseline 依實作記錄；該文件在 `specs/` 移除前不應被當作依據。
