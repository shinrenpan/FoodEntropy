## 1. Baseline 文件化

- [x] 1.1 從 `FoodItem` struct 與 `RecordStatus` / `ExpiryStatus` 兩個 enum 寫出 requirement「A food item carries a stored record status and a derived expiry status」；驗證：`grep -rn "ExpiryStatus" Sources/Core/Persistence` 無結果，確認效期狀態未進入持久化層。
- [x] 1.2 從 `ExpiryStatus.daysUntil` 的 `startOfDay` 實作寫出 requirement「Expiry is measured in calendar days in the device's time zone」；驗證：該函式對 `today` 與 `expiryDate` 皆先取 `calendar.startOfDay(for:)` 再取 `dateComponents([.day])`。
- [x] 1.3 從 `ExpiryStatus.evaluate` 的三段判斷與 `nearExpiryWindowDays` 常數寫出 requirement「The expiry day itself counts as near-expiry, not expired」；驗證：`Tests/FoodEntropyTests/ExpiryStatusTests.swift` 已覆蓋 `daysUntil` 為負值、0、門檻值與門檻+1 的邊界。
- [x] 1.4 從 `daysUntil` / `evaluate` 的 static 純函式簽章與 `FoodItem` 的便利方法寫出 requirement「Expiry evaluation is a pure function with injectable today and calendar」；驗證：兩函式皆帶 `today: Date = .now, calendar: Calendar = .current` 參數，且 `FoodItem.expiryStatus` 僅轉呼叫而未重複實作判斷。
- [x] 1.5 從 `SwiftDataManager` 的 `update` / `markConsumed` / `markWasted` / `delete` 與 `resolve` 私有方法寫出 requirement「An item leaves the active list through one of four exits」；驗證：`resolve` 同時設定 `statusRaw` 與 `resolvedAt`，`delete` 呼叫 `context.delete`，而 `update` 不改動 `statusRaw`。

## 2. 收尾

- [x] 2.1 執行 `spectra validate baseline-food-item`；驗證：指令回傳成功、無 error。
- [x] 2.2 archive 後補上 `openspec/specs/food-item/spec.md` 的 `## Purpose` 段；驗證：`grep -c "TBD" openspec/specs/food-item/spec.md` 為 0。
