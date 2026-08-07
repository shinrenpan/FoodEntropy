## Context

「移除廣告」是一次性的非消耗型購買，也是 app 內唯一的金流。StoreKit 2 提供 `Transaction.currentEntitlements` 作為「使用者目前持有什麼」的權威來源，並以 `Transaction.updates` 串流推送購買、退款與撤銷。整個 `StoreManager` 的設計就是盡可能少做事：不儲存、不快取、不自行判斷，只把 StoreKit 的答案轉成一個布林值。

## Goals / Non-Goals

**Goals:**
- 記錄 entitlement 為唯一真相、不自存旗標的理由與其防住的兩個問題。
- 記錄啟動對帳與更新監聽的分工。
- 記錄購買結果的判定條件（含使用者取消與 pending）。
- 記錄還原購買按鈕在「技術上多餘、審核上必要」之間的定位。
- 記錄購買中的防重入。

**Non-Goals:**
- 無行為變更。
- 不涵蓋 `advertising` 的載入與呈現、`settings-ui` 的版面、`app-shell` 的截圖模式。

## Decisions

### entitlement 是唯一真相，本機不存任何已購買旗標

`adsRemoved` 由 `Transaction.currentEntitlements` 逐筆檢查推導：product ID 相符且 `revocationDate` 為 nil 才算持有。沒有任何 `UserDefaults` 或資料庫欄位記錄購買狀態。理由：自存旗標會同時製造兩個問題。其一，退款與家長撤銷不會回頭改寫本機旗標——使用者拿回了錢卻繼續享有無廣告版本；其二，寫在 `UserDefaults` 的解鎖狀態是可竄改的，越獄裝置或備份編輯即可白拿。以 entitlement 為準則讓兩者同時消失，且換裝置時同一 Apple ID 自動生效。代價是每次啟動都要向 StoreKit 查詢一次，這是可忽略的成本。考慮過的替代方案：以本機旗標作為快取、entitlement 作為背景校正——否決，快取存在的那段時間窗正是漏洞窗口，而它換來的效能收益接近於零。

`revocationDate` 的檢查不可省略：`currentEntitlements` 仍可能包含已撤銷的交易。

### 啟動時做一次對帳，並常駐監聽交易更新

`start()` 依序做三件事：註冊 `Transaction.updates` 監聽、載入商品、對帳 entitlement。監聽以 `guard updatesTask == nil` 保證只註冊一次。理由：啟動對帳處理「上次關閉 app 之後發生的變化」（在其他裝置購買、退款核准），而更新監聽處理「app 執行期間發生的變化」（本次購買完成、退款即時生效）。兩者缺一都會有一段狀態不同步的時間。重複註冊監聽會導致同一筆交易被處理多次，因此以 nil 檢查防止。

### 只有通過驗證的交易才算數，且必須 finish

購買結果為 `.success` 時，仍要 `case .verified` 才承認；承認後呼叫 `transaction.finish()` 再重新對帳。`.userCancelled` 與 `.pending` 一律回傳未持有。理由：`.success` 只代表流程走完，未通過簽章驗證的交易不能當作有效購買。`finish()` 是 StoreKit 2 的要求——未 finish 的交易會持續出現在 `updates` 串流中。`.pending`（例如需要家長批准）此刻確實尚未持有，之後批准時會經由 `updates` 串流通知，屆時自然轉為持有。

購買後不直接把 `adsRemoved` 設為 true，而是重新對帳一次再讀回。理由：讓「持有」這件事永遠只有一條判定路徑。

### 保留還原購買，儘管技術上多數情況不需要

設定畫面保留「還原購買」，實作為 `AppStore.sync()` 後重新對帳。理由：以 entitlement 為真相的設計下，換裝置或重裝時只要登入同一 Apple ID，購買狀態會自動恢復，Restore 按鈕在正常情況下是多餘的。但 Apple 的審核慣例要求非消耗型 IAP 必須提供明確的還原入口，缺少它是常見的退件原因。它同時也是異常情況下的最後手段（entitlement 因故未同步時強制向 App Store 拉取）。

### 購買與還原期間阻擋重複觸發

設定畫面以 `purchaseInFlight` 旗標擋住購買中的重複點擊，購買與還原共用同一個旗標。理由：StoreKit 的購買會開啟系統彈窗，重複觸發會造成多個彈窗排隊或 API 錯誤。共用旗標則避免使用者在購買進行中又按下還原。

### 商品未載入時購買不可用

`removeAdsProduct` 為 optional，載入失敗時 `purchaseRemoveAds()` 直接回傳未持有，設定畫面的價格文字為空字串。理由：沒有 `Product` 物件就無從發起購買。此時不阻斷其他功能，只是該列無價格可顯示。

## Implementation Contract

**Behavior (observable):**
- 購買成功後首頁廣告立刻消失，切換 Tab 與重啟後維持消失。
- 使用者在購買彈窗按取消，狀態維持未購買，無錯誤提示。
- 退款核准後，app 重新啟動（或執行期收到更新）時廣告重新出現。
- 在另一台同 Apple ID 的裝置安裝 app，無需按還原即為已購買狀態。
- 購買進行中重複點擊購買或還原不會觸發第二次流程。
- 網路異常導致商品載入失敗時，設定列不顯示價格，點擊購買無反應而非崩潰。

**Interface / data shape:**
- `StoreManager`：`@MainActor final class`；`static let removeAdsProductID`；`private(set) var adsRemoved: Bool`；`private(set) var removeAdsProduct: Product?`；`private var updatesTask: Task<Void, Never>?`。
- `init(adsRemoved: Bool = false)`：僅供測試與預覽注入初始狀態。
- `start() async`、`refreshProducts() async`、`refreshEntitlements() async`、`purchaseRemoveAds() async throws -> Bool`、`restore() async`。
- 設定畫面狀態：`adsRemoved`、`removeAdsPriceText`、`purchaseInFlight`、`showPurchaseError`。

**Acceptance criteria:**
- `grep -rn "adsRemoved" Sources` 顯示沒有任何 `UserDefaults` 或持久化寫入路徑。
- `refreshEntitlements` 同時檢查 product ID 相符與 `revocationDate == nil`。
- `listenForTransactionUpdates` 以 `updatesTask == nil` 防止重複註冊。
- `purchaseRemoveAds` 在 `.success` 後仍檢查 `.verified`，並呼叫 `transaction.finish()`。
- 購買與還原分支皆以 `purchaseInFlight` 防重入。

**Scope boundaries:**
- In scope：entitlement 推導、啟動對帳與更新監聽、購買與還原流程、退款撤銷反映、防重入、商品載入失敗處理。
- Out of scope：廣告的載入與呈現（`advertising`）、設定畫面版面（`settings-ui`）、截圖模式的注入（`app-shell`）、App Store Connect 的商品設定與審核附註。

## Risks / Trade-offs

- [每次啟動都查詢 StoreKit] → 啟動時的 entitlement 對帳是非同步的，在它完成之前 `adsRemoved` 維持初始值 `false`，因此已購買的使用者在啟動瞬間可能短暫看到廣告位。可接受，但這是唯一會讓付費使用者看到廣告的情況。
- [購買錯誤僅以一個布林旗標呈現] → 設定畫面只有 `showPurchaseError`，不區分網路錯誤、驗證失敗或其他原因，使用者無從得知該如何處理。
- [`.pending` 與失敗都回傳 false] → 呼叫端無法區分「等待家長批准」與「購買失敗」，因此無法給出「已送出，等待批准」這類正確的提示。以此 app 的使用者輪廓（成人自用）風險低，但家庭共享情境下體驗不佳。
- [`init(adsRemoved:)` 可注入已購買狀態] → 這個入口存在的目的是測試與預覽，但它也是 `app-shell` 記錄的截圖模式所使用的路徑。該路徑必須永遠留在 `#if DEBUG` 內，否則等同免費解鎖；此約束由 `app-shell` 承擔。
