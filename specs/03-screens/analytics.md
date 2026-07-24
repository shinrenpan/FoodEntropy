# 03 · 分析（⚠️ 已於 v1.0.0 併入首頁）

> 狀態：🗄️ **已合併進 `home.md`**（原獨立分頁移除）
> 原因：分析頁的分桶清單與首頁食材雷同（兩頁重複）。改為單頁——現況甜甜圈 +
> 浪費統計併到首頁頂部，分桶清單改用首頁互動 row。`AnalyticsView/ViewModel/
> HostController` 已刪除，內容併入 `HomeView/HomeViewModel`。
> **本文件僅保留為設計脈絡參考，實作以 `home.md` 為準。**

---

現存食材依效期狀態分桶的總覽。以下為原分析頁設計（現況圖表 + 浪費統計的規格仍適用，已搬到首頁）。

---

## 資料來源

- 同首頁：**只取 `active`** 食材（不含 `consumed` / `wasted`，故與「已使用純存不露出」不衝突）。
- 依 `ExpiryStatus`（`02-architecture` §5）分三桶。

---

## 版面（v2，issue #4）

由上而下：**現況圖表 → 浪費統計 → 分桶明細**。技術用 Swift Charts（原生）。

### 1. 現況（Swift Charts donut）
- 甜甜圈圖顯示 active 三桶（已過期🔴 / 3天內🟡 / 期限內🟢）佔比，中心顯示總數。
- 右側 legend：色點 + 桶名 + 數量（**不靠顏色單獨辨識**，符合無障礙；色彩沿用 `expiryColor`）。
- 無 active 時顯示「目前沒有食材」。

### 2. 浪費統計（近 30 天滾動視窗）
- 資料來源：`SwiftDataManager.fetchResolvedFoods()`（consumed + wasted），VM 依 `resolvedAt` 只計**近 30 天**（滾動視窗，舊資料自然不影響；`wasteWindowDays` 常數）。
- **浪費率 hero 數字** = 丟棄 /（吃掉 + 丟棄），≥30% 標紅；配綠/紅比例條 + 「吃掉 N · 丟棄 N」。
- 無已處理紀錄時顯示「尚無已處理紀錄」。
- **資料保存**：標記已使用 / 丟棄時**剝離圖片**（`imageData=nil`，省本機/iCloud 空間）。
- **清除歷史**：本區 header 右側「清除」鈕（**就近原則**，控制與其影響的統計同區；`hasHistory` 為 all-time 判斷，只要有任何已處理紀錄即露出，避開 30 天視窗顯示空、但仍有舊資料可清的邊界）；點擊 → 確認 alert → `deleteResolvedFoods()` 全數刪除 → 重撈歸零。

### 3. 分桶明細（唯讀清單，同 v1）

依 **急 → 緩** 排列三個 Section，各 Section header 顯示「桶名 + 數量」：

| 順序 | Section | 條件 | 顏色 |
|---|---|---|---|
| 1 | 已過期未處理 | `expired`（daysUntil < 0） | 🔴 |
| 2 | 3 天內到期 | `nearExpiry`（0–3） | 🟡 |
| 3 | 保存期限內 | `fresh`（> 3） | 🟢 |

- **空桶照樣顯示**，header 標「0 項」（「沒有過期品」本身也是有用資訊）。
- 每桶內 row 依到期日升冪。

---

## Row 內容（唯讀）

- 與首頁 row 相同資訊：縮圖 / 名稱 / 到期資訊（到期日 + 剩餘天數），但**無任何互動**（不可滑、不可點、不可編輯）。

---

## 刷新

- `onAppear` 重撈：`manager.fetchActiveFoods()` → 重新分桶。

---

## State（草案）

```swift
extension AnalyticsViewModel {
  struct State: Equatable, Sendable {
    var expired: [FoodItem] = []
    var nearExpiry: [FoodItem] = []
    var fresh: [FoodItem] = []
    // 數量 = 各陣列 count（header 顯示用）
  }
}
```

## Action（草案）

```swift
enum ViewAction {
  case onAppear             // fetch active + resolved → 分桶 / 統計 → 更新 State
  case clearHistoryDidTap   // → 顯示確認 alert
  case clearHistoryConfirmed // → deleteResolvedFoods() → reload
}
```

---

## 備註

- 本畫面刻意極簡且與首頁共用資料，差異在「分桶唯讀總覽」vs「平鋪可操作」（`01-navigation` §1 分工原則）。
- 未來若擴充統計（消耗率、浪費量、`consumed` / `wasted` 歷史彙總），於此畫面演進。
