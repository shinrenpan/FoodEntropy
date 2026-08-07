## Summary

補回 v1.0.0 的食材表單 baseline：新增與編輯共用單一畫面兩模式、名稱與日期的驗證規則、以快照比對判定未儲存變更、自訂返回鈕以攔截放棄確認、照片的取得與移除，以及儲存後的權限請求與排程對帳。無行為變更。

## Motivation

表單有三件事需要規格保護：

**一、返回鈕是自訂的，不是系統預設。** 畫面隱藏了系統返回鈕、改放自己的「取消」，因為系統返回鈕直接 pop，無法攔下來詢問「要放棄變更嗎」。這看起來像是多此一舉的重造輪子，實際上是唯一能在返回前插入確認的做法。

**二、「有沒有改過」由 ViewModel 持有的初始快照比對決定，而快照刻意不含 UI-only 欄位。** 若把 `showDiscardConfirm` 這類純顯示旗標也納入比對，光是彈出確認框本身就會讓狀態「變髒」。這個排除很細微，但錯了會造成確認框關不掉的循環。

**三、到期日不早於購買日有兩道防線。** 到期日選擇器的下限綁定購買日（擋住直接選更早的日期），而購買日被改晚時再把到期日一併推後（擋住反向造成的無效區間）。只做其中一道都會留下漏洞。

## Proposed Solution

從 `Sources/Features/FoodForm/FoodFormViewModel.swift`、`FoodFormViewModel+Models.swift`、`FoodFormMode.swift`、`FoodFormView.swift`、`FoodFormHostController.swift` 與 `specs/03-screens/form.md` 寫出 `food-form-ui` capability spec，涵蓋：兩種模式的標題與初值、欄位驗證與儲存啟用條件、日期區間的雙向約束、未儲存變更的判定與放棄確認、照片的取得／移除與大圖預覽、儲存流程的順序，以及本畫面刻意不提供的操作。

## Non-Goals

- 無行為變更。
- 不涵蓋照片的壓縮參數與落地方式，那屬 `persistence`；本畫面只負責觸發取得與傳遞結果。
- 不涵蓋通知的排程規則與權限狀態語意，那屬 `notification`；本 capability 只規範儲存流程中呼叫它們的時機與順序。
- 不涵蓋 push 進入與返回的導航機制，那屬 `navigation`。
- 不涵蓋首頁的清單與 row 操作，那屬 `home-ui`。
- 不涵蓋四種出口的資料語意，那屬 `food-item`。

## Capabilities

### New Capabilities

- `food-form-ui`：新增／編輯雙模式表單、欄位驗證與日期約束、未儲存變更判定與放棄確認、自訂返回鈕、照片取得與移除、儲存流程順序。

### Modified Capabilities

（無）

## Impact

- Affected specs: new `food-form-ui`
- Affected code:
  - New: （無 —— 記錄既有程式碼）
  - Modified: （無）
  - Removed: （無）
  - Reference: `Sources/Features/FoodForm/FoodFormViewModel.swift`, `Sources/Features/FoodForm/FoodFormViewModel+Models.swift`, `Sources/Features/FoodForm/FoodFormMode.swift`, `Sources/Features/FoodForm/FoodFormView.swift`, `Sources/Features/FoodForm/FoodFormHostController.swift`, `specs/03-screens/form.md`
