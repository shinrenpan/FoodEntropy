# 03 · 首頁（統計 + 食材清單，單頁）

> 狀態：✅ 定案（v1.0.0 合併分析頁）
> 上游：`../01-navigation.md`（§2）、`../02-architecture.md`
> 對應：`HomeView` + `HomeViewModel`（@Observable @MainActor）

App **唯一的清單頁**，兼「現況統計」與「管理食材」。原「分析」分頁已併入本頁（見 `analytics.md` 說明）：頂部放現況甜甜圈 + 浪費統計，下方分桶清單改用互動 row。

---

## 資料來源與排序

- **active 食材**：依 `ExpiryStatus` 分三桶（已過期未處理 / 3 天內 / 保存期限內），桶內依**到期日升冪**、次序 `createdAt` 升冪。
- **已處理（consumed/wasted）**：僅供浪費統計彙總（近 30 天視窗），不列於清單。

---

## 版面（由上而下）

1. **廣告 = `AdSlotView`**（`safeAreaInset` top 釘在清單頂，不透明底防穿透）
   - AdMob 非個人化 banner（`BannerAdView`，`AdSizeBanner` 320x50），右上標「廣告」（`02-architecture` §9）。
   - **有 fill → 50pt 顯示；無 fill / 載入失敗 → 收合為 0**（不留空框）。
   - **`adsRemoved` 為 true 時整條不放**（由 IAP entitlement 驅動，見 `02-architecture` §7）。
2. **現況甜甜圈**（`StatusChartSection`）：active 三桶佔比 + 中心總數；無 active 顯示「目前沒有食材」。
3. **浪費統計**（`WasteStatsSection`）：近 30 天浪費率 hero + 綠/紅比例條 + 吃掉/丟棄數；header 右側「清除歷史」鈕（`hasHistory` 才露出）；無紀錄顯示「尚無已處理紀錄」。
4. **分桶清單**：三個 Section（急→緩），header 桶名 + 數量，**空桶顯示「沒有項目」**；桶內 row 可互動（見下方 Row 操作）。最後一桶 footer 顯示互動 hint。
5. **新增按鈕 = `AddButton`**（`safeAreaInset` bottom）：**全寬填滿**「＋ 新增食材」→ push `FoodFormView(.add)`。取代原小圓 FAB；底部 padding 與 tab bar 拉開避免誤觸。

### 空狀態（無 active 食材）
- 甜甜圈「目前沒有食材」、三空桶「沒有項目」、浪費統計「尚無已處理紀錄」。
- 底部「＋ 新增食材」始終可用。

---

## Row 內容

| 元素 | 說明 |
|---|---|
| 縮圖 | 有圖顯示壓縮圖；無圖顯示預設圖示 |
| 名稱 | 食材名稱 |
| 到期資訊 | 到期日 + 剩餘天數 / 狀態文字（例：「還有 2 天」/「今天到期」/「已過期 3 天」） |
| 狀態顏色 | 🟢 `fresh`（>3）/ 🟡 `nearExpiry`（0–3 天）/ 🔴 `expired`（<0） |

- **不顯示購買日期**（保持精簡，購買日於編輯 Form 才見）。
- 剩餘天數文字由 `daysUntil` 產生（`02-architecture` §5）。

---

## Row 操作

| 觸發 | 操作 | 行為 |
|---|---|---|
| 向右滑（leading） | 標記已使用 | 直接執行 → `consumed`，移出清單 |
| 向左滑（trailing） | 刪除 | **跳確認** → hard delete |
| 長按 → context menu | 延長效期 / 標記已使用 / 標記丟棄 | 不重複滑動 / 點擊已有的操作 |
| 單點整列 | 編輯 | push `FoodFormView(.edit)` |

- **發現性（issue #2）**：長按選單只放**滑動與點擊之外**的操作（延長、丟棄），避免重複；並在清單非空時於 Section footer 顯示 hint：「點項目可編輯；長按可延長效期或標記丟棄」。
- **延長效期**：彈出快捷 date picker（僅選新到期日），選完即存、不離開首頁；存後重排通知（`02-architecture` §8）。
- **確認規則**：僅**刪除**跳確認（不可復原）；已使用 / 丟棄 / 延長不跳確認。
- 已使用 / 丟棄 → 設 `statusRaw` + `resolvedAt`，取消該食材通知。
- **swipe 刪除實作注意**：刪除鈕不可用 `role: .destructive`（會在點擊時自動移除 row），改 `.tint(.red)`；真正刪除由確認後的 `deleteConfirmed` 執行（issue #1）。

---

## 刷新

- `onAppear` 重撈（`02-architecture` §4）：自 Form / 任何 push 返回時觸發，`manager.fetchActiveFoods()` → 更新 `state.items`。

---

## State（草案）

```swift
extension HomeViewModel {
  struct State: Equatable, Sendable {
    var items: [FoodItem] = []            // active，已排序
    var adsRemoved: Bool = false          // 來自 IAP entitlement
    var pendingDeleteItem: FoodItem? = nil // 刪除確認對象
    var extendingItem: FoodItem? = nil     // 延長 date picker 對象
    var isEmpty: Bool { items.isEmpty }
  }
}
```

---

## Action（doAction 單一進入點，草案）

```swift
enum Action {
  case onAppear
  case tapAdd                       // FAB → push add
  case tapRow(FoodItem)             // → push edit
  case swipeConsume(FoodItem)       // leading
  case requestDelete(FoodItem)      // trailing → 顯示確認
  case confirmDelete
  case cancelDelete
  case menuExtend(FoodItem)         // → 顯示 date picker
  case commitExtend(Date)
  case menuConsume(FoodItem)
  case menuWaste(FoodItem)
  case menuDelete(FoodItem)         // → 顯示確認
  case menuEdit(FoodItem)           // → push edit
}
```

---

## 交由後續處理

- 廣告 SDK 接法（AdMob 元件、非個人化廣告 fallback）與 ATT 流程 → `02-architecture` 已定策略，實作細節於 `04-tasks`。
- V 層版面（row 高度、FAB 樣式、顏色 token）依 `mvvmc-view` 於實作階段定。
