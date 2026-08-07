## Context

食材有兩種「狀態」，性質完全不同：使用者對它做了什麼（收在資料庫裡），以及它現在離到期還有多久（每次讀取當下重算）。把兩者混為一談是這個 domain 最容易犯的錯——一旦有人把 `ExpiryStatus` 存進 `@Model`，資料就會在跨日的那一刻起與現實脫節，而且是靜默的：清單看起來正常，只是顏色與分桶停留在寫入當天。

## Goals / Non-Goals

**Goals:**
- 記錄兩軸狀態的分工，以及 `ExpiryStatus` 不得持久化的理由與後果。
- 記錄日曆日差演算法與三段邊界，特別是「到期當天算 nearExpiry」的產品理由。
- 記錄判定函式可注入基準日期與曆法的設計意圖。
- 記錄四種出口的狀態轉移與留痕差異。

**Non-Goals:**
- 無行為變更。
- 不涵蓋落地機制（`persistence`）、畫面呈現（`home-ui`）、通知排程（`notification`）。

## Decisions

### 兩軸狀態：RecordStatus 存、ExpiryStatus 算

`RecordStatus`（active / consumed / wasted）持久化，代表使用者對這項食材做過什麼。`ExpiryStatus`（fresh / nearExpiry / expired）永不持久化，每次讀取時由 `expiryDate` 與當下日期算出。理由：效期狀態是時間的函式，不是事實的紀錄——同一筆食材今天是 `nearExpiry`、四天後就是 `expired`，中間沒有任何「事件」發生可以觸發更新。若存進資料庫，就需要一個每日跑一次的更新任務去改寫所有列，而該任務在 app 未開啟時不會執行，資料必然過期。算出來則永遠正確且零維護成本。考慮過的替代方案：存 `ExpiryStatus` 並在啟動時批次更新——否決，那是拿寫入放大與資料不一致風險，換一個 `O(1)` 計算本來就不貴的東西。

### 到期當天是 nearExpiry，不是 expired

`daysUntil == 0` 判為 `nearExpiry`（黃），要到 `daysUntil < 0`（隔天）才轉 `expired`（紅）。理由：多數食材在標示到期當天仍可食用，把它標成紅色「已過期未處理」會促成不必要的丟棄——與本 app「減少食物浪費」的目的相反。另一個一致性理由：到期提醒就在當天早上 09:00 發出，若使用者點開通知看到的是已經變紅的「過期」項目，通知與畫面在同一天互相矛盾。考慮過的替代方案：當天即標紅以加強急迫感——否決，急迫感由 `nearExpiry` 的黃色與排序（到期日升冪，當天到期者自然排最前）承擔已經足夠。

### 以日曆日差比較，不用時間差

`daysUntil` 先把「今天」與「到期日」各自取當地時區的 `startOfDay`，再取兩者的日曆日差。理由：使用者心中的「還有幾天」是日曆概念，不是 24 小時的倍數。若直接用時間差，早上八點記下的「明天到期」與晚上十一點記下的「明天到期」會算出不同天數；取當日起點則兩者都是 1 天。用當地時區而非固定時區，是因為到期是使用者生活中的概念。

### 判定是純函式，且可注入基準日期與曆法

`ExpiryStatus.daysUntil` 與 `evaluate` 是 static 純函式，`today` 與 `calendar` 都有預設值但可注入。理由：跨日、跨時區、月底與閏年的邊界正是最容易出錯的地方，而這些情況無法靠「等到明天再測」來驗證。可注入基準日期讓每一種邊界都能寫成一個確定性的單元測試。`FoodItem` 上的便利方法只是轉呼叫這兩個純函式，不重複實作邏輯。

### 四種出口：三種留紀錄狀態，一種真刪

延長效期改 `expiryDate` 但維持 `active`；標記已使用轉 `consumed`；標記丟棄轉 `wasted`；刪除是 hard delete。前三者都留下資料列（後兩者並記錄 `resolvedAt`），只有刪除不留痕。理由：`consumed` 與 `wasted` 是浪費統計的原始素材——沒有它們就算不出浪費率；而「刪除」的語意是「這筆根本不該存在」（打錯字、誤加），把它算進統計會污染分母。三者在 UI 上都是「從清單消失」，但資料意義完全不同。

### nearExpiry 門檻是具名常數

`nearExpiryWindowDays = 3` 宣告為常數而非散落的字面值。理由：這是產品可調參數（`02-architecture` §5 明說可滾動調整），集中一處才能在調整時不遺漏，也讓「3」在程式碼中有名字可讀。

## Implementation Contract

**Behavior (observable):**
- 一筆到期日為今天的食材顯示為「3 天內到期」，不是「已過期」。
- 一筆到期日為昨天的食材顯示為「已過期未處理」。
- 一筆到期日為今天 +3 天的食材仍屬「3 天內到期」；+4 天則為「保存期限內」。
- 跨過午夜後重新開啟 app，狀態自動反映新的一天，無需任何資料寫入。
- 標記已使用或丟棄後，該筆從清單消失但仍計入浪費統計；刪除後則完全不計入。
- 延長效期後該筆留在清單，並依新到期日重新排序與著色。

**Interface / data shape:**
- `FoodItem`：`Identifiable`、`Equatable`、`Sendable` 的 struct；`id` 與 `createdAt` 為 `let`，其餘為 `var`；`resolvedAt` 與 `imageData` 為 optional。
- `RecordStatus`：`String` raw value enum，`Sendable`，三個 case。
- `ExpiryStatus`：`String` raw value enum，`Sendable`，三個 case；不出現在任何 `@Model` 的屬性上。
- `ExpiryStatus.nearExpiryWindowDays: Int`、`daysUntil(expiryDate:today:calendar:) -> Int`、`evaluate(expiryDate:today:calendar:) -> ExpiryStatus`。
- `FoodItem.expiryStatus(today:calendar:)` 與 `daysUntilExpiry(today:calendar:)` 轉呼叫上述純函式。

**Acceptance criteria:**
- `grep -rn "ExpiryStatus" Sources/Core/Persistence` 無結果——效期狀態不出現在持久化層。
- 以固定 `today` 注入時，`evaluate` 對 `daysUntil` 為 `-1` / `0` / `3` / `4` 分別回傳 `expired` / `nearExpiry` / `nearExpiry` / `fresh`。
- `daysUntil` 對同一組日期，無論當日時分秒為何都回傳相同結果。

**Scope boundaries:**
- In scope：Domain model 形狀、兩軸狀態、日差演算法與邊界、四種出口的轉移語意。
- Out of scope：持久化與查詢（`persistence`）、狀態的視覺呈現與手勢（`home-ui`）、依到期日的通知排程（`notification`）、浪費統計的計算式（`home-ui`）。

## Risks / Trade-offs

- [`ExpiryStatus` 不持久化，因此無法用資料庫 predicate 直接篩選] → 分桶必須在取回全部 active 資料後於記憶體中進行，資料量極大時會是瓶頸。以本 app 的規模（個人食材清單）可忽略；真的成為問題時，iOS 27 的 Sectioned Queries 是既定的升級路徑。
- [判定依賴裝置當地時區與系統時鐘] → 使用者手動改系統日期會直接改變所有食材的顯示狀態。接受此代價：這正是「日曆日」語意應有的行為，且無防禦的必要。
- [`nearExpiryWindowDays` 若調整，既有使用者的清單分桶會在更新後當場改變] → 沒有資料遷移問題（因為狀態是算的），但視覺上會有一批食材突然換桶。調整時需視為產品變更而非參數微調。
