## Summary

補回 v1.0.0 已上架的導航規格 baseline：stateless 的 push-based `AppRouter`、把「當初怎麼進來的」記在目的地上以決定 `back()` 該 pop 還是 dismiss 的轉場記憶機制、互動返回手勢的啟用條件、`onRoute` 路由意圖模式，以及集中式 `Deeplink` 解析與三個進入點的收斂。無行為變更。

## Motivation

`AppRouter` 是憲章列為鐵則的那一條——「不繞過 Router 做導航」——的實作本體，但它幾個最容易被誤改的設計目前只存在於程式碼註解裡：

- **轉場樣式記在 `UIViewController` 的 associated object 上**，而不是由呼叫端在 `back()` 時再說一次。這使得 `back(from:)` 能自己判斷該 pop 還是 dismiss，HostController 永遠只需要叫 `back`。這個機制若被「簡化」成傳參數，每個 HostController 就得記住自己是怎麼被叫出來的。
- **互動返回手勢只在預設 push 轉場時啟用**。自訂轉場動畫與 UIKit 的互動式 pop 手勢不相容，放行會造成手勢中斷後的畫面錯位。這條限制在程式碼裡只是一行 `guard`。
- **push-based 而非 present-based**，這與同一組 mvvmc-* skills 下的 HerbMeet 相反。原因是首頁的刷新機制依賴 pop 回來時觸發 `onAppear` 重撈——本專案沒有 `@Query`，清單不會自動響應。

補這份 baseline 的過程也順帶盤點出 `AppRouter` 的實際使用面：v1.0.0 只用到 `to`（皆為預設 push）、`back`、`sheet` 三個入口，其餘 API 與整套自訂轉場動畫尚未被任何呼叫端使用。這個落差記在 design 裡，讓未來要不要收斂 API 表面成為一個有依據的決定。

## Proposed Solution

從 `Sources/App/AppRouter.swift`、`Sources/App/Deeplink.swift`、`Sources/App/SceneDelegate.swift` 的 deeplink 處理，以及三個 HostController 的 `handleRouter` 實作，寫出 `navigation` capability spec，涵蓋：`onRoute` 路由意圖模式、stateless router 的 context 取得方式、預設 push 導航、轉場記憶與 `back()` 分流、page sheet 呈現、互動手勢啟用條件、離開 App 不算導航的界線，以及集中式 deeplink 解析與三進入點收斂。

## Non-Goals

- 無行為變更，不動任何一行 Swift。
- 不涵蓋 window 與 tab bar 的裝配——那是 `app-shell` 的範圍，本 capability 只規範在其之上的導航行為。
- 不重述 `mvvmc-navigation` skill 的規則；只記錄本專案的實際實作與其偏離／延伸之處。
- 不把 v1.0.0 未使用的 `AppRouter` API（`backTo`、`backToRoot`、`deeplink`、`tab`）與未使用的轉場樣式（`.modal`、`.fade` 及其 animator）寫成 requirement——規格描述現行契約，不描述尚未啟用的可能性。是否收斂這些 API 屬未來獨立 change。
- 不涵蓋各畫面內部的導航流細節（首頁 row 的四種出口、Form 的儲存流程），那些屬各畫面自己的 capability。

## Capabilities

### New Capabilities

- `navigation`：push-based `AppRouter`、轉場記憶與 `back()` 分流、互動手勢條件、`onRoute` 路由意圖模式、集中式 `Deeplink` 解析與三進入點收斂。

### Modified Capabilities

（無）

## Impact

- Affected specs: new `navigation`
- Affected code:
  - New: （無 —— 記錄既有程式碼）
  - Modified: （無）
  - Removed: （無）
  - Reference: `Sources/App/AppRouter.swift`, `Sources/App/Deeplink.swift`, `Sources/App/SceneDelegate.swift`, `Sources/Features/Home/HomeHostController.swift`, `Sources/Features/FoodForm/FoodFormHostController.swift`, `Sources/Features/Settings/SettingsHostController.swift`, `specs/01-navigation.md`
