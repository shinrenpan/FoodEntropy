## Problem

分桶清單以 sheet 呈現時，從 Spotlight、Siri 或通知經 deeplink 開啟某一筆食材，畫面看起來沒有反應：sheet 仍在原位，編輯頁其實已經推到 sheet 底下的根導覽堆疊上，使用者要手動關掉 sheet 才看得到。`foodentropy://home`（通知點擊的預設目的地）與「目標食材已不在」兩條路徑同樣不會收掉 sheet，使用者停在清單上。

2026-10-07 在 iPhone Duo 模擬器外螢幕（Xcode 27.1 RC，iOS 27.1）實測重現：開「3 天內到期」清單 sheet → `foodentropy://item/<另一桶食材 uuid>` → 點系統確認框「打開」→ sheet 仍在；按「完成」關掉後，目標食材的編輯頁出現在底下。

這違反 `navigation` 規格已有的要求（「returning to the home screen alone is a failure」，例子表「a bucket's list → home screen, then the requested item's detail」）。

## Root Cause

deeplink 經 `SceneDelegate` 的處理器呼叫 `AppRouter.resetTo`（開啟食材）或 `AppRouter.backToRoot`（首頁、目標已不在），兩者都只改動根導覽控制器的 `viewControllers`，不處理根導覽控制器上方 present 出來的畫面。分桶清單在 `restyle-home-as-card-stack`（2026-09-16）改為 sheet 呈現後，這條路徑就沒有被涵蓋；當時的 deeplink 修正（`fix-deeplink-dropped-push`，2026-09-15）早於 sheet 化。

## Proposed Solution

`AppRouter.resetTo` 與 `AppRouter.backToRoot` 在改動堆疊之前，先檢查根導覽控制器是否有 presented 的畫面；有的話先以不帶動畫的方式 dismiss，並在 dismiss 的 completion 內才設定堆疊。這兩個方法目前只有 deeplink 處理器呼叫，語意本來就是「回到根部」，所以把「收掉 modal」納入其中，呼叫端不需要改。

不在同一個 runloop 內連續做 dismiss 與堆疊設定：既有的教訓（`fix-deeplink-dropped-push`）是 UIKit 會丟棄前一次導航尚未落定期間的下一次導航。

## Non-Goals

- 不改 deeplink 的解析與進入點（`Deeplink` enum、SceneDelegate 的四個入口）。
- 不改分桶清單的呈現方式（維持 sheet）。
- 不處理多 scene（`UIApplicationSupportsMultipleScenes` 維持 false）；也不處理 `AppRouter.deeplink(_:)` 死碼與全域找 window 的寫法（另案）。
- 不處理一般導航（非 deeplink）在 sheet 開著時的行為；只有 deeplink 會在「畫面上可能是任何東西」時觸發導航。

## Success Criteria

- 分桶清單 sheet 開著時開啟食材 deeplink：sheet 收掉，最終堆疊為「首頁 → 該食材的編輯頁」，編輯頁可見。
- sheet 開著時 `foodentropy://home` 或目標已不在：sheet 收掉，停在首頁。
- 隱私權政策（Safari）sheet 開著時開啟食材 deeplink：同樣收掉並顯示編輯頁。
- 沒有 sheet 時行為不變（既有 `AppRouterTests` 全部通過）。
- 驗證：新增 `AppRouterTests` 斷言 dismiss 後的最終堆疊；iPhone Duo 或 iPhone 18 Pro 模擬器以 `simctl openurl` 重現步驟手動確認（系統確認框由作者手動點擊）。

## Impact

- Affected code:
  - Modified: Sources/App/AppRouter.swift, Tests/FoodEntropyTests/AppRouterTests.swift
  - New: （無）
  - Removed: （無）
- Affected specs: `navigation`（兩條 deeplink 要求補上「presented 畫面」的情境）
