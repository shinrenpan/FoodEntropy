## Why

食材表單的儲存路徑有兩個自 v1.0.0 起就在正式版裡的缺陷，兩者都會讓使用者相信「已經存好了」而其實沒有。

第一，`FoodFormViewModel` 的儲存動作沒有進行中的防護。唯一的 guard 是 `state.isSaveEnabled`，而它只檢查名稱非空——在整段儲存期間恆為 true，畫面上的儲存鈕綁的也是同一個條件。寫入本身是同步的，但其後接著請求通知權限（一次與通知 daemon 的 XPC 往返）與重建排程（最多 60 次循序的通知註冊）。表單在這整段時間仍留在畫面上、鈕仍可按，第二次點擊會走另一條 Task 再建一筆。同專案的購買流程有 `purchaseInFlight` 防護，儲存路徑沒有。

第二，寫入失敗時表單照常關閉。`add-app-intents` 已讓資料層把寫入失敗丟給呼叫端，但表單把它接成 `try?` 丟掉，接著照原流程關閉畫面。`persistence` 目前允許「純呈現資料的呼叫端忽略失敗」，理由是**畫面沒變**本身就告訴使用者什麼都沒發生——這個理由對首頁的列操作成立（列還在），對表單不成立：表單關閉正是這個 app 用來表示「成功」的訊號。磁碟滿或 CloudKit 衝突時，使用者看到表單收起、回到首頁，食材不在清單裡，也不會有到期提醒。

## What Changes

- 儲存動作加入進行中狀態：進行中時再次觸發直接忽略，儲存鈕同時失效。
- 寫入失敗時表單**不關閉**，改以警示告知失敗；使用者輸入原樣保留，可直接重試。
- 寫入失敗時**不**請求通知權限、**不**重建排程——沒有東西被寫進去，那兩步沒有對象。
- 修正 `persistence` 中「畫面可以忽略寫入失敗」的條件：把免責範圍收斂到「失敗後畫面維持不變」的呼叫端；會在成功時收起自身畫面的呼叫端不適用。
- 新增的使用者可見字串走 String Catalog，英文為來源語言並補 `zh-Hant` 翻譯。

## Non-Goals (optional)

- 不改首頁列操作（已使用／丟棄／刪除／延長／清除歷史）的靜默行為。詳細理由見 design。
- 不加到期前提醒或任何新功能。
- 不改資料層的錯誤型別、不新增重試或佇列機制。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `food-form-ui`: 儲存流程的 requirement 目前只描述成功路徑（寫入 → 請求權限 → 重建排程 → 關閉）。需補上進行中不得重複觸發，以及寫入失敗時停在表單、不關閉、不執行後續兩步。
- `persistence`: 「畫面忽略寫入失敗」的免責條件需收斂——理由是失敗後畫面不變，故只適用於失敗後畫面確實不變的呼叫端。

## Impact

- Affected specs: `food-form-ui`（修改）、`persistence`（修改）
- Affected code:
  - Modified:
    - `Sources/Features/FoodForm/FoodFormViewModel.swift`
    - `Sources/Features/FoodForm/FoodFormViewModel+Models.swift`
    - `Sources/Features/FoodForm/FoodFormView.swift`
    - `Sources/Resources/Localizable.xcstrings`
    - `Tests/FoodEntropyTests/FoodFormViewModelTests.swift`
  - New: (none)
  - Removed: (none)
