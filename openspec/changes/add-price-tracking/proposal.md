## Summary

為食材加入選填的價格欄位，並以**前瞻**為主軸呈現金額：在食材還來得及被吃掉時顯示「即將到期的金額」，而非在丟棄後才顯示損失。回顧型的已丟棄金額保留為附屬資訊。排定 v1.1.0。

## Motivation

首頁目前只用比例與數量描述狀況——「浪費率 20%」「3 天內到期 5 項」。兩者都偏抽象，不會讓人採取行動。金額會：它是使用者唯一能直接感受的單位，也直接對上這個 app 存在的理由。

至於金額該指向哪個時間點（已經丟掉的損失，或即將發生的損失），是本 change 的核心決定，見下節。

同時它是 v1.1.0 的更新亮點，展現上架後持續迭代。

## 已確定的部分（資料層）

- `FoodItemEntity` 新增 `price: Double?`——**選填**、optional，符合 `persistence` 的 CloudKit-safe 約束與「schema 只加不改」的演進限制。
- 加欄位屬 additive，**需重新部署 CloudKit Production schema**（只加不刪，安全）。
- Form 加入**選填**價格欄位，不列入 `food-form-ui` 的儲存啟用條件——強迫填寫會讓使用者不想記錄，選填才符合「降低輸入負擔」的既有取向。
- 幣別依裝置 locale 格式化，不硬寫任何貨幣符號——`localization` 已規範「金額與日期交由系統格式化，不自行組字串」。

## 呈現方式：前瞻為主，回顧為附屬

**被否決的做法：以「本月丟掉了 NT$350」為主軸。**

價格選填代表任一期間內只有部分丟棄項帶價格。若丟了 10 項、其中 3 項有價格而顯示「NT$150」，使用者的反應是「才 150 嘛」——原本要用金額**加強**警覺，卻做出一個會**安慰人**的數字，比原本的百分比更沒有壓力。涵蓋率越低，數字越安慰人。

它還有第二個問題：**新使用者看不到任何東西**。剛安裝的人沒有丟棄紀錄，30 天視窗內是空的，要用滿一個月才長出數字。

而最根本的問題是它**事後才說話**。食物已經丟了，數字只能讓人懊悔，改變不了任何事。

**採用的做法：金額指向未來，而非過去。**

主軸改為「即將到期的金額」——在食材還救得回來時說話。同一批價格資料、同樣的低估問題，但性質完全不同：

- **還來得及。** 這正是本 app 存在的目的。
- **第一天就有數字。** 使用者記錄第一項帶價格的食材就看得到，不需要等 30 天。
- **低估的後果小得多。** 「至少 NT$300 快到期」被低估只是提醒力道弱一點；「只丟了 NT$150」被低估則是給了錯誤的安心。前者失真無害，後者失真有害。
- **可隨時補正。** 前瞻型看的是 active 食材，使用者隨時能進 Form 補填價格，補完立刻反映在金額上——回顧型看的已丟棄項目則沒有編輯入口（見下方「既有限制」）。
- **餵得動 Widget。** 為 `add-widget` 提供了「環形圖 + 數量」之外的具體資訊。

回顧型的已丟棄金額**保留為附屬**：浪費統計區維持現有的百分比為主，金額以低調的一行呈現，不作為 hero，因此不會產生「才 150 嘛」的效果。

### 已定案的 UI 決定

1. **價格語意為「這筆記錄的總花費」**，非單價。無數量欄位，一筆記錄即一次採購。介面上不加冗長說明——Form 是使用者自行操作的頁面，本 app 主打簡單。
2. **輸入方式**：數字鍵盤（`.decimalPad`），開放小數（全球發行，非台幣地區需要）；幣別符號依裝置 locale 呈現，使用者不輸入符號，顯示交由系統格式化（見 `localization`）。
3. **不在首頁提供快速補填入口。** 長按選單已有三項（延長／已使用／丟棄），再加會過長；點 row 進 Form 本就是編輯的正規路徑。
4. **沒有任何 active 食材帶價格時，該行完全不顯示**——不放引導文案。首頁已有廣告位、環形圖、浪費統計、三個桶與新增按鈕，在尚未證明有用的功能上先佔版面並不划算。待測試後再評估是否加入引導。

### 既有限制（影響涵蓋率）

已標記為已使用／丟棄的食材**沒有編輯入口**——Form 只從 active 清單進入。因此價格必須在食材離開清單前填寫，否則該筆永遠不會計入回顧型金額。這是選擇前瞻為主軸的另一個理由：前瞻型只看 active 食材，完全不受此限制影響。

本 change 不新增已處理食材的編輯入口。

## Proposed Solution

前瞻金額顯示於首頁，取自 active 且 `expiryStatus` 為 `nearExpiry` 的食材中已記錄價格者的總和，以「至少」語氣呈現。回顧金額顯示於浪費統計區，沿用該區既有的近 30 天滾動視窗，作為附屬資訊。資料層依「已確定的部分」實作。

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
- `home-ui`：新增「即將到期金額」的前瞻呈現；浪費統計區新增已丟棄金額作為附屬資訊。

### New Capabilities

（無）

四份 delta spec 隨本 change 提供。

## Impact

- Affected specs: `food-item`, `persistence`, `food-form-ui`, `home-ui`
- Affected code:
  - Modified: `Sources/Core/Domain/FoodItem.swift`, `Sources/Core/Persistence/FoodItemEntity.swift`, `Sources/Core/Persistence/SwiftDataManager.swift`, `Sources/Features/FoodForm/FoodFormView.swift`, `Sources/Features/FoodForm/FoodFormViewModel*.swift`, `Sources/Features/Home/HomeView.swift`, `Sources/Features/Home/HomeViewModel*.swift`
- 外部作業：CloudKit Production schema 重新部署（additive）
- 排程：v1.1.0
