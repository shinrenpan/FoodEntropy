## Summary

補回 v1.0.0 的首頁 baseline：單頁承載現況統計與可操作清單（原分析分頁已於 v1.0.0 併入）、三桶分法與空桶照顯示、近 30 天滾動視窗的浪費統計、四種 row 操作的分工與確認規則，以及刪除確認期間該列必須留在清單上的要求。無行為變更。

## Motivation

首頁是這個 app 唯一的清單頁，也是唯一動手的地方。它有三件事需要規格保護：

**一、刪除確認尚未回答前，該列必須還在清單上。** SwiftUI 的 `swipeActions` 若把刪除鈕標為 destructive role，點擊當下 SwiftUI 會立刻把該列移出清單——但此時確認對話框才剛彈出，使用者若選「取消」，資料還在、畫面上的列卻已經消失，要等下次重撈才回來。這是已修過的實際缺陷（issue #1），修法是不使用 destructive role、只保留紅色外觀。若不寫成規格，任何人「順手」把它改回語意正確的 destructive role 就會重現。

**二、清除歷史鈕的露出條件是 all-time，統計本身卻是近 30 天。** 兩者刻意不一致：若清除鈕也看 30 天視窗，使用者在超過 30 天沒有處理任何食材時會看到「尚無已處理紀錄」且沒有清除鈕，但資料庫裡其實還留著更早的歷史無法清除。這個邊界很容易在重構時被「統一」掉。

**三、分桶空桶照樣顯示。** 「沒有過期品」本身就是使用者想知道的資訊，把空桶隱藏會讓畫面在最理想的狀態下反而資訊最少。

## Proposed Solution

從 `Sources/Features/Home/HomeView.swift`、`HomeViewModel.swift`、`HomeViewModel+Models.swift`、`Sources/Core/Components/FoodRowView.swift` 與 `specs/03-screens/home.md`、`specs/03-screens/analytics.md` 寫出 `home-ui` capability spec，涵蓋：版面組成與釘頂釘底元素、三桶分法與排序來源、現況圖表與其無障礙要求、浪費統計的視窗與清除條件、四種 row 操作與確認規則、刪除確認期間的列存續、資料變動後的重載與通知重排，以及空狀態。

## Non-Goals

- 無行為變更。
- 不涵蓋效期狀態的判定演算法與四種出口的資料語意，那屬 `food-item`。
- 不涵蓋查詢排序與圖片剝離，那屬 `persistence`；本 capability 只消費其結果。
- 不涵蓋廣告版位自身的載入與收合行為，那屬 `advertising`；本 capability 只規範它被放在哪、以及何時不放。
- 不涵蓋通知排程規則，那屬 `notification`；本 capability 只規範「資料變動後要觸發對帳」。
- 不涵蓋 Form 畫面本身，那屬 `food-form-ui`。

## Capabilities

### New Capabilities

- `home-ui`：首頁版面、三桶分法與空桶顯示、現況圖表與無障礙、浪費統計視窗與清除條件、四種 row 操作與確認規則、刪除確認期間的列存續、重載與通知重排時機、空狀態。

### Modified Capabilities

（無）

## Impact

- Affected specs: new `home-ui`
- Affected code:
  - New: （無 —— 記錄既有程式碼）
  - Modified: （無）
  - Removed: （無）
  - Reference: `Sources/Features/Home/HomeView.swift`, `Sources/Features/Home/HomeViewModel.swift`, `Sources/Features/Home/HomeViewModel+Models.swift`, `Sources/Core/Components/FoodRowView.swift`, `specs/03-screens/home.md`, `specs/03-screens/analytics.md`
