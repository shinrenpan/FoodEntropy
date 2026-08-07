## 1. Baseline 文件化

- [x] 1.1 從 `HomeView.body` 的 `safeAreaInset` 與 Section 組成寫出 requirement「The home screen carries both the current overview and the working list」；驗證：`HomeView` 內同時存在 `StatusChartSection`、`WasteStatsSection`、三個 `BucketSection`、頂部 `AdSlotView` 與底部 `AddButton`；`Sources` 內已無 `AnalyticsView` / `AnalyticsViewModel` / `AnalyticsHostController`。
- [x] 1.2 從 `handleDataResponse` 的三桶 filter 與 `BucketSection` 的無條件渲染寫出 requirement「Items are grouped into three expiry buckets, most urgent first, and empty buckets still appear」；驗證：三個 `BucketSection` 依「已過期未處理 → 3 天內到期 → 保存期限內」順序宣告且無 `if` 包裹，桶內未再排序。
- [x] 1.3 從 `StatusChartSection` 的 `donut()` 與 `legend()` 寫出 requirement「The status chart is legible without relying on colour」；驗證：`legend()` 對每個桶輸出色點 + 名稱 + 數量；中心顯示 active 總數；空狀態文字存在。
- [x] 1.4 從 `handleDataResponse` 的視窗過濾與 `State.wasteRate` 寫出 requirement「Waste statistics cover a rolling recent window and distinguish no data from zero」；驗證：以 `wasteWindowDays` 常數計算 cutoff 並過濾 `resolvedAt`；`wasteRate` 在 `resolvedTotal == 0` 時回傳 nil。
- [x] 1.5 從 `state.hasHistory` 的賦值與 `WasteStatsSection` 的 header 條件寫出 requirement「Clearing history is offered whenever any history exists at all」；驗證：`hasHistory = !resolved.isEmpty` 使用未經 30 天過濾的集合，與 `windowed` 分開。
- [x] 1.6 從 `BucketSection.row` 的 `swipeActions` / `contextMenu` 與 `ViewAction` 列舉寫出 requirement「Each row offers four distinct actions across separate gestures」；驗證：leading swipe 為標記已使用、trailing swipe 為刪除、整列點擊發出 `rowDidTap`；`contextMenu`（第 339–344 行）實含延長效期、標記已使用、標記丟棄**三項**，不含刪除與編輯——與同處註解及 `03-screens/home.md` 宣稱的「只放滑動／點擊之外的動作」不符，spec 依實作現況記錄，落差記於 design 的 Risks。
- [x] 1.7 從 trailing swipe 未使用 `role: .destructive` 與 `deleteDidTap` / `deleteConfirmed` / `deleteCancelled` 三段流程寫出 requirement「Only deletion asks for confirmation, and the row stays until the user answers」；驗證：`HomeView.swift` 的 trailing swipe 按鈕以 `.tint(.red)` 取代 `role: .destructive`（第 329–336 行含說明此陷阱的註解與 issue #1 參照）；`deleteDidTap` 只設 `pendingDeleteItem`，實際 `manager.delete` 發生在 `deleteConfirmed`。
- [x] 1.8 從 `reload()` / `reloadAndReschedule()` 的呼叫分布寫出 requirement「The screen reloads on appearing and reconciles reminders after data changes」；驗證：`consumeDidTap`、`wasteDidTap`、`deleteConfirmed`、`extendCommitted` 皆呼叫 `reloadAndReschedule()`，`onAppear` 與 `clearHistoryConfirmed` 呼叫 `reload()`。
- [x] 1.9 從最後一桶 `BucketSection` 的 `footer` 參數寫出 requirement「A hint describes the gestures that are not otherwise discoverable」；驗證：`HomeView.swift:30` 對第三桶傳入含點擊／滑動／長按說明的 footer 文字。

## 2. 收尾

- [x] 2.1 執行 `spectra validate baseline-home-ui`；驗證：指令回傳成功、無 error。
- [x] 2.2 archive 後補上 `openspec/specs/home-ui/spec.md` 的 `## Purpose` 段；驗證：`grep -c "TBD" openspec/specs/home-ui/spec.md` 為 0。
