## Context

deeplink（Spotlight、Siri、通知、URL scheme）全部經 `SceneDelegate` 的單一處理器，最後呼叫 `AppRouter.resetTo`（開啟食材）或 `AppRouter.backToRoot`（首頁、目標已不在）。兩者只改根導覽控制器的 `viewControllers`。分桶清單（`BucketListHostController` 包在自己的 `UINavigationController` 裡，以 pageSheet present）與隱私權政策（`SFSafariViewController`，pageSheet）都是 present 在首頁之上的 modal，不在根堆疊裡，所以 deeplink 不會收掉它們：開啟食材時編輯頁被推到 sheet 底下。2026-10-07 實測重現。

`resetTo` 與 `backToRoot` 目前只有 `SceneDelegate` 的 deeplink 處理器呼叫（`grep` 確認，共三處）。

## Goals / Non-Goals

**Goals:**

- 有 modal 開著時，deeplink 先收掉 modal，再把根堆疊設成目標狀態；最終使用者看到的就是目標畫面。
- 沒有 modal 時行為與現行完全相同。

**Non-Goals:**

- 不改 `Deeplink` 解析、進入點與 `SceneDelegate` 的處理器分支。
- 不改分桶清單與隱私權政策的呈現方式。
- 不處理多 scene，不處理 `AppRouter.deeplink(_:)` 死碼。
- 不改非 deeplink 的導航。

## Decisions

### Dismiss presented screens inside resetTo and backToRoot

把「先收掉 modal」放進 `AppRouter.resetTo` 與 `AppRouter.backToRoot`，而不是放在 `SceneDelegate`：導航一律收在 Router（`navigation` 規格），而且這兩個方法的語意本來就是「回到根部」，modal 也是根部之上的東西。呼叫端不必改。

替代方案：在 `SceneDelegate.handle` 先呼叫一次 dismiss 再呼叫 Router——要在處理器裡處理 completion 與時序，等於把導航邏輯放回進入點，違反規格「no entry point carries navigation logic of its own」。

### Set the stack in the dismiss completion

有 presented 畫面時，以 `animated: false` dismiss，並在 completion 內才 `setViewControllers` 或 `popToRootViewController`。沒有 presented 畫面時直接設定，與現行相同。

不在同一個 runloop 內連續 dismiss 與設定堆疊：`fix-deeplink-dropped-push` 的實測教訓是 UIKit 會丟棄前一次導航尚未落定期間的下一次導航，結果是目標畫面不出現且沒有任何錯誤。completion 是 UIKit 保證 dismiss 落定的時點。

dismiss 對象是根導覽控制器的 `presentedViewController`（由根導覽控制器呼叫 `dismiss`），會一併收掉其上整條 presentation 鏈（例如清單 sheet 內再 present 的延長效期 sheet）。

## Implementation Contract

**行為：**

- 分桶清單 sheet（含其內已推入的編輯頁）、隱私權政策 sheet、或任何 modal 開著時：
  - 食材 deeplink → modal 收掉，根堆疊為「首頁 → 該食材編輯頁」，編輯頁可見。
  - `foodentropy://home`、通知點擊、目標已不在 → modal 收掉，根堆疊只剩首頁。
- 沒有 modal 時：與現行完全相同。

**介面：** `AppRouter.resetTo(_:from:style:animated:)` 與 `AppRouter.backToRoot(from:animated:)` 簽章不變。

**失敗模式：** 若 `source` 沒有 navigationController 或堆疊為空，維持現行的 `assertionFailure` 並返回。

**驗收：**

- `AppRouterTests` 新增測試：根導覽控制器 present 一個畫面後呼叫 `resetTo`／`backToRoot`，斷言 completion 之後 `presentedViewController == nil` 且堆疊為「根部 + 目標」或「只有根部」。測試需把導覽控制器掛到 host app 的 window 上才能真的 present；若測試環境無法 present，改為記錄排除理由並以模擬器手動驗證。
- 既有 `AppRouterTests` 全部通過。
- 模擬器手動：開「3 天內到期」清單 sheet → `xcrun simctl openurl <udid> foodentropy://item/<另一桶食材 uuid>` → 作者點確認框 → 編輯頁可見、sheet 已關。另以隱私權政策 sheet 與 `foodentropy://home` 各做一次。

**範圍：** 只改 `AppRouter.resetTo`、`AppRouter.backToRoot` 與其測試。

## Risks / Trade-offs

- [`backToRoot` 現在會收掉 modal，若日後有非 deeplink 的呼叫端可能不預期] → 目前只有 deeplink 使用；在方法註解寫明「含收掉 modal」。
- [dismiss 不帶動畫，sheet 瞬間消失] → deeplink 來自 app 之外，沒有需要延續的視覺脈絡（同 `fix-deeplink-dropped-push` 對 `animated: false` 的判斷）。
- [completion 非同步，測試需等待] → 測試以 `confirmation` 或輪詢 `presentedViewController` 等待 completion。
