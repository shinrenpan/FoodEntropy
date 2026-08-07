## Summary

補回 v1.0.0 的食材 domain model baseline：兩軸狀態（儲存的 `RecordStatus` 與計算的 `ExpiryStatus`）、以日曆日差為準的效期判定演算法，以及食材離開清單的四種出口語意。無行為變更。

## Motivation

「兩軸狀態」是整個 app 最容易被誤解的一件事：`RecordStatus` 是持久化的（active / consumed / wasted），`ExpiryStatus` 是每次讀取當下算出來的（fresh / nearExpiry / expired）。兩者名字都叫 status、都是三態、都影響清單呈現，但一個進資料庫一個永遠不進。CLAUDE.md 用兩行帶過，沒有可檢核的規格。

更細但同樣容易失守的是判定邊界：**到期當天算 nearExpiry，不算 expired**。這不是差一天的實作細節，而是產品判斷——多數食材當天仍可食用，且通知就在當天早上發出；若當天就標成紅色「已過期」，通知與畫面會自相矛盾。這條規則目前只活在 `FoodItem.swift` 的一行 `if days <= nearExpiryWindowDays`，以及 `02-architecture` 的一段表格裡。

四種出口（延長／已使用／丟棄／刪除）的差異也需要固定：哪些留紀錄、哪些不留，直接決定浪費統計的分母。

## Proposed Solution

從 `Sources/Core/Domain/FoodItem.swift` 與 `specs/02-architecture.md` §2 §5 寫出 `food-item` capability spec，涵蓋：Domain model 的欄位與不可變性、兩軸狀態的分工與 `ExpiryStatus` 不得持久化的禁令、日曆日差演算法與三段邊界、可注入基準日期的純函式設計，以及四種出口的狀態轉移與留痕差異。

## Non-Goals

- 無行為變更。
- 不涵蓋這些狀態如何落地與查詢——`@Model` 的 CloudKit-safe 約束、`toDomain()` 邊界、排序與圖片剝離屬 `persistence`。
- 不涵蓋各畫面如何呈現狀態（顏色、分桶、滑動手勢），那屬 `home-ui`。
- 不涵蓋依到期日排程通知的規則，那屬 `notification`。
- 不定義浪費統計的計算方式，只定義它的資料前提（哪些出口留紀錄）。

## Capabilities

### New Capabilities

- `food-item`：食材 Domain model、`RecordStatus` / `ExpiryStatus` 兩軸狀態、日曆日差判定演算法、四種出口的轉移語意。

### Modified Capabilities

（無）

## Impact

- Affected specs: new `food-item`
- Affected code:
  - New: （無 —— 記錄既有程式碼）
  - Modified: （無）
  - Removed: （無）
  - Reference: `Sources/Core/Domain/FoodItem.swift`, `Sources/Core/Persistence/SwiftDataManager.swift`, `specs/02-architecture.md`
