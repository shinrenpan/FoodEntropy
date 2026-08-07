## Summary

把「系統邊緣滑動返回會離開表單而不詢問未儲存變更」從 baseline 記錄的待驗證風險，改為明載的刻意決策。無行為變更，僅修正規格對既有行為的描述。

## Motivation

`baseline-food-form-ui` 把這個行為記為 Risks 中的未驗證項目，措辭暗示它可能是缺陷。它不是：邊緣滑動返回是 iOS 的系統層手勢，使用者做出這個動作時清楚知道結果是離開當前畫面。攔截它反而會與系統慣例衝突——使用者在其他 app 養成的預期是「滑就是走」，多一道詢問會讓手勢感覺失靈。

留著錯誤的措辭有兩個實際成本。其一，未來有人讀到那條 Risk，可能會花時間去「修好」一個沒有壞的東西，或加上手勢攔截而破壞系統慣例。其二，`navigation` 的手勢啟用條件（只在預設 push 轉場放行）目前允許表單使用該手勢；若有人誤以為表單應被排除，可能會為此加上例外，讓 router 的條件變得依畫面而異。

## Proposed Solution

修改 `food-form-ui` 的 requirement「Leaving with unsaved changes asks first, and leaving unchanged does not」，把它的適用範圍明確限定為 app 自己提供的返回控制項；並新增一條 requirement 記錄系統手勢返回刻意不攔截，以及它對 `navigation` 手勢條件的意涵。

## Non-Goals

- 無行為變更，不動任何一行 Swift。
- 不改變 `navigation` 的手勢啟用條件。
- 不為表單新增任何手勢攔截或例外。
- 不涵蓋 `food-form-ui` 的其他 requirement。

## Capabilities

### Modified Capabilities

- `food-form-ui`：限定放棄確認的適用範圍為 app 的返回控制項，並新增系統手勢返回的刻意行為。

### New Capabilities

（無）

## Impact

- Affected specs: `food-form-ui`
- Affected code:
  - New: （無）
  - Modified: （無 —— 僅修正規格描述）
  - Removed: （無）
  - Reference: `Sources/Features/FoodForm/FoodFormView.swift`, `Sources/App/AppRouter.swift`
