# 03 · 首頁（食材清單）

> 狀態：✅ 定案
> 上游：`../01-navigation.md`（§2）、`../02-architecture.md`
> 對應：`HomeView` + `HomeViewModel`（@Observable @MainActor）

App 主畫面，管理食材：瀏覽、新增、滑動 / 長按操作。

---

## 資料來源與排序

- **只顯示 `active`** 食材（`consumed` / `wasted` / 已刪除皆不列）。
- **排序：到期日升冪**（越早到期越前）；已過期者 `daysUntil` 為負，故排在最上方（最需處理者最顯眼）。
- 同到期日 → 次序以 `createdAt` 升冪（暫定，可調）。

---

## 版面（由上而下）

1. **廣告 section = `AdSlotView`**（固定最上方，單一則）
   - **v1**：佔位 seam——DEBUG 顯示「Ad Placeholder」框、Release collapse（`02-architecture` §9）。
   - 未來接 AdMob 後：與食材 row 視覺明顯區隔、標示「廣告」。
   - **`adsRemoved` 為 true 時隱藏**（v1 寫死 false；未來由 IAP entitlement 驅動，見 `02-architecture` §7）。
2. **食材清單**（rows）
3. **FAB**（浮於清單下方）→ 點擊 push `FoodFormView(.add)`

### 空狀態（無 active 食材）
- 廣告 section **照常顯示**。
- 顯示空狀態 hint（例：「目前還沒有食材，點下方＋開始記錄」），構成 publisher content。

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
