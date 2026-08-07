## Summary

補回 v1.0.0 的到期通知 baseline：到期當天 09:00 的排程時機、每項食材一則、以「清空重建」對帳取代逐筆增刪、iOS 待發通知上限的最近到期優先處置、情境式權限請求，以及點擊通知的 payload 慣例。無行為變更。

## Motivation

通知這一層有一個關鍵的架構選擇沒有被記錄：**排程不是逐筆維護的，而是每次整批重建的**。新增、編輯、延長、標記、刪除都不各自去排程或取消對應的那一則通知，而是統一呼叫一次對帳——清空全部待發通知，再依當前 active 清單重排。這讓「排程 / 取消 / 重排」三種操作退化成同一件事，也讓漏改一個路徑不會造成殘留的幽靈通知。若不知道這個設計，後來的人很容易「順手補上」逐筆的取消邏輯，反而破壞一致性。

第二件事是 **iOS 每個 app 只能有 64 則待發通知**。這個上限沒有錯誤回報——超過的部分是靜默丟棄的。實作預留 headroom 只排 60 則，並以最近到期者優先。使用者食材超過 60 項時，較遠期的項目不會有提醒，這是已知且刻意的取捨。

第三是 `NotificationService` 內另有一個 DEBUG-only 的即時觸發模式（10 秒後發、且不篩掉已過期者），與 `app-shell` 記錄的那組環境開關屬同一類風險：它若洩漏到 Release，使用者每次資料變動都會被通知轟炸。

## Proposed Solution

從 `Sources/Core/Notification/NotificationService.swift`、`SceneDelegate` 的前景對帳與通知回呼，以及 `specs/02-architecture.md` §8 寫出 `notification` capability spec，涵蓋：排程時機與單位、對帳策略、上限處置、過期不排、權限請求時機與狀態分流、payload 慣例、前景呈現，以及 DEBUG 模式的隔離要求。

## Non-Goals

- 無行為變更。
- 不涵蓋點擊通知後的路由實作，那屬 `navigation`；本 capability 只規範 payload 的內容慣例。
- 不涵蓋設定畫面的通知列版面與被拒引導文案，那屬 `settings-ui`。
- 不涵蓋效期狀態的判定演算法，那屬 `food-item`；本 capability 只使用到期日。
- 不涵蓋自訂提醒天數或時間——v1.0.0 刻意不提供，且不在此規格的擴充範圍內。

## Capabilities

### New Capabilities

- `notification`：到期通知的排程時機與單位、清空重建的對帳策略、待發上限處置、權限請求時機、payload 慣例、前景呈現、DEBUG 模式隔離。

### Modified Capabilities

（無）

## Impact

- Affected specs: new `notification`
- Affected code:
  - New: （無 —— 記錄既有程式碼）
  - Modified: （無）
  - Removed: （無）
  - Reference: `Sources/Core/Notification/NotificationService.swift`, `Sources/App/SceneDelegate.swift`, `Sources/Features/FoodForm/FoodFormViewModel.swift`, `Sources/Features/Settings/SettingsViewModel.swift`, `specs/02-architecture.md`
