## Problem

從 Siri、到期通知或 Spotlight 開啟某個食材時，若畫面上已經推著任何一層（正在編輯另一筆食材、或停留在設定頁），使用者會被彈回首頁，而**目標食材不會被開啟**。沒有錯誤、沒有提示、沒有崩潰——看起來就像那個動作被忽略了。

只有在使用者剛好停在首頁時，deeplink 才會正確抵達編輯表單。

`navigation` 的 requirement「A single food item is a deeplink destination」已經規定了正確行為（「the second item's detail replaces the first rather than stacking on top of it」），實作沒有做到。這不是規格缺口，是實作缺陷。

缺陷自 v1.0.0 起即存在，v1.3.0 仍在。它在 `remove-tab-bar` 的實作期間以受控實驗查出，但與該改動無關——相關的兩行程式碼在該改動前後逐字相同。

## Root Cause

`SceneDelegate` 的 `showFoodItem` 在**同一個 runloop turn** 內連續做兩件事：

1. `popToRootViewController(animated: false)` ——把既有畫面收掉
2. 透過 `AppRouter` push 編輯表單

UIKit 在前一次導航尚未落定時會丟棄後續的 push。結果是 pop 生效、push 消失，stack 停在只剩首頁的狀態。

2026-09-15 的實驗結果（直接呼叫真正的 `handle(_:)`，記錄 stack 內容）：

- 從首頁收到 deeplink → `[Home, FoodForm]`，正確
- 已有畫面推著時收到 deeplink → `[Home]`，表單消失

兩次走的是同一段程式碼，唯一差別是 stack 深度是否大於一——也就是那個 `popToRootViewController` 有沒有被執行到。

## Proposed Solution

讓 pop 先落定再 push，而不是在同一個 runloop turn 內連續呼叫。

實作上有兩個可行方向，由 design 選定其一：把「回到根部並推入目標」合成單一次原子的 stack 設定，或是在 pop 之後讓出一個 runloop turn 再 push。前者少一次畫面跳動，後者改動面更小。

無論採哪一種，導航都必須仍然經由 `AppRouter`，以維持轉場樣式與返回手勢的既有行為。

## Non-Goals (optional)

- 不改 `Deeplink` 的 URL 格式與解析。
- 不改四個進入點（冷啟動 URL、熱啟動 URL、通知點擊、App Intents 待處理目標）各自的觸發時機，只改抵達之後的導航動作。
- 不改「目標食材已不存在時停在首頁且不報錯」的既有行為。
- 不為此缺陷加入使用者可見的錯誤提示——正確行為是抵達目標，不是告知失敗。
- 不改首頁版面、設定頁或資料層。

## Success Criteria

- 從首頁收到食材 deeplink → 抵達該食材的編輯表單（維持現有正確行為）。
- **正在編輯另一筆食材時**收到食材 deeplink → 抵達新食材的編輯表單，且 stack 不疊層（符合 requirement 既有的 scenario「Following two item links in succession」）。
- **停留在設定頁時**收到食材 deeplink → 設定被收掉並抵達該食材的編輯表單。
- 目標食材已不存在時 → 回到首頁、不呈現任何 detail、不報錯。
- 上述四種情形皆以記錄 navigation stack 內容的方式驗證，而非僅憑截圖。
- 完整測試套件通過且測試數不減少。

## Impact

- Affected code:
  - Modified:
    - `Sources/App/SceneDelegate.swift`
    - `Sources/App/AppRouter.swift`
  - New:
    - `Tests/FoodEntropyTests/AppRouterTests.swift`
  - Removed: (none)
