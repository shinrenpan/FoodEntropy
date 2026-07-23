# 03 · 分析（唯讀總覽）

> 狀態：✅ 定案
> 上游：`../01-navigation.md`（§3）、`../02-architecture.md`
> 對應：`AnalyticsView` + `AnalyticsViewModel`（@Observable @MainActor）

現存食材依效期狀態分桶的**唯讀**總覽。不可滑動、不可編輯、無 FAB、無點擊操作。

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
- **資料保存**：標記已使用 / 丟棄時**剝離圖片**（`imageData=nil`，省本機/iCloud 空間）；紀錄可於設定「清除歷史統計」全數刪除。

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
enum Action {
  case onAppear   // fetch active → 分桶 → 更新 State
}
```

---

## 備註

- 本畫面刻意極簡且與首頁共用資料，差異在「分桶唯讀總覽」vs「平鋪可操作」（`01-navigation` §1 分工原則）。
- 未來若擴充統計（消耗率、浪費量、`consumed` / `wasted` 歷史彙總），於此畫面演進。
