## Summary

為食材加入選填的價格欄位，並在浪費統計中呈現丟棄的金額。**資料層已定案**（見「已確定的部分」）；**統計的呈現方式待討論**，癥結不在版面而在一個會反噬功能目的的風險，見「待討論：呈現方式」。排定 v1.1.0。

## Motivation

浪費統計目前只有「浪費率 %」與「丟棄 N 項」。百分比與數量偏抽象——「這個月浪費率 20%」不會讓人痛。金額會：「這個月丟掉了 NT$350 的食物」直接對上這個 app 存在的理由。

同時它是 v1.1.0 的更新亮點，展現上架後持續迭代。

## 已確定的部分（資料層）

- `FoodItemEntity` 新增 `price: Double?`——**選填**、optional，符合 `persistence` 的 CloudKit-safe 約束與「schema 只加不改」的演進限制。
- 加欄位屬 additive，**需重新部署 CloudKit Production schema**（只加不刪，安全）。
- Form 加入**選填**價格欄位，不列入 `food-form-ui` 的儲存啟用條件——強迫填寫會讓使用者不想記錄，選填才符合「降低輸入負擔」的既有取向。
- 幣別依裝置 locale 格式化，不硬寫任何貨幣符號——`localization` 已規範「金額與日期交由系統格式化，不自行組字串」。

## 待討論：呈現方式

**核心風險：部分填價格會讓金額系統性低估，而低估的金額比沒有金額更糟。**

價格是選填的（這個設計正確），但這代表任一統計期間內，丟棄項目中只有一部分帶價格。假設丟了 10 項、其中 3 項有價格，畫面顯示「本月丟掉 NT$150」——使用者的反應會是「才 150 嘛」。

這與本功能的目的完全相反：原本要用金額**加強**警覺，結果做出一個會**安慰人**的數字，甚至比原本的百分比更沒有壓力。涵蓋率越低，數字越安慰人。

### 候選方向

| | 做法 | 評估 |
|---|---|---|
| A | 僅當丟棄項全數有價格時才顯示金額 | 幾乎不會觸發，等同不做 |
| B | 顯示金額並標示涵蓋範圍：「NT$150（10 項中 3 項已記錄價格）」 | 誠實，但文字冗長且稀釋衝擊力 |
| C | 改用「至少」語氣：「**至少**丟掉了 NT$150」 | 一個詞解決低估問題，衝擊力保留 |
| D | 不做總額，改點名**單筆最貴的丟棄**：「你丟掉了一塊 NT$280 的牛排」 | 完全不受涵蓋率影響；具體物品比總額更有畫面感 |

### 初步傾向（待確認）

**C + D 並用**：hero 位置放「至少 NT$X」，下方一行點名該期間最貴的單筆丟棄。C 讓總額不說謊，D 補上 C 缺少的具體性——且 D 天然只取「已記錄價格」的子集合，不需要任何免責說明。

原有的浪費率百分比**保留**，與金額並存：百分比反映行為（改善看得出來），金額反映代價（有衝擊力），兩者資訊不重複。

### 待決問題

1. 採用哪個方向（或組合）？
2. 金額的統計視窗是否沿用 `home-ui` 現有的近 30 天滾動視窗？
3. 「最貴單筆」若同時有多筆同價，如何取捨？
4. 完全沒有任何丟棄項帶價格時，該顯示什麼——沿用現有的空狀態文字，或另設一句引導使用者開始記錄價格？
5. 編輯既有食材時補填價格，是否影響已計入統計的歷史紀錄？（`persistence` 在標記已使用／丟棄時會剝離圖片，但不動其他欄位；價格欄位在 resolve 後仍可編輯與否需一併決定）

## Proposed Solution

待呈現方式定案後補上 design 與 tasks。資料層部分無待決事項，可先行實作，但 UI 未定前不宜開始——欄位一旦寫入使用者資料就難以回頭調整語意。

## Non-Goals

- 不做預算設定或消費目標追蹤。
- 不做價格的自動帶入或商品資料庫查詢——純手動選填。
- 不涵蓋 Pro 分層下的「歷史趨勢圖」（屬另一個尚未決定的項目，且以本 change 的價格欄位為前提）。
- 不改變既有浪費率的計算方式。

## Capabilities

### Modified Capabilities

- `food-item`：Domain model 新增選填價格欄位。
- `persistence`：`@Model` 新增 optional 屬性（additive），CloudKit Production schema 需重新部署。
- `food-form-ui`：新增選填價格欄位；不影響儲存啟用條件。
- `home-ui`：浪費統計新增金額呈現（**內容待定**）。

### New Capabilities

（無）

delta spec 待呈現方式定案後撰寫——`home-ui` 的部分現在無法寫出可驗證的 scenario。

## Impact

- Affected specs: `food-item`, `persistence`, `food-form-ui`, `home-ui`
- Affected code:
  - Modified: `Sources/Core/Domain/FoodItem.swift`, `Sources/Core/Persistence/FoodItemEntity.swift`, `Sources/Core/Persistence/SwiftDataManager.swift`, `Sources/Features/FoodForm/FoodFormView.swift`, `Sources/Features/FoodForm/FoodFormViewModel*.swift`, `Sources/Features/Home/HomeView.swift`, `Sources/Features/Home/HomeViewModel*.swift`
- 外部作業：CloudKit Production schema 重新部署（additive）
- 排程：v1.1.0
