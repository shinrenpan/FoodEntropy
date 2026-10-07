## 1. 收掉 modal 再設定堆疊

- [x] 1.1 A single food item is a deeplink destination（Dismiss presented screens inside resetTo and backToRoot；Set the stack in the dismiss completion）：`AppRouter.resetTo` 在根導覽控制器有 presented 畫面時，先以 `animated: false` dismiss，並在 completion 內才 `setViewControllers([root, destination])`；沒有 presented 畫面時行為不變。驗證：先寫失敗測試——在 `AppRouterTests` 把導覽控制器掛到 host app 的 window，present 一個畫面後呼叫 `resetTo`，等待完成後斷言 `presentedViewController == nil` 且堆疊為「根部 + 目標」；若無法在測試中 present，記錄排除理由。既有 `AppRouterTests` 全數通過。
- [x] 1.2 Deeplink parsing is centralised in one enum（首頁目的地收掉 modal）：`AppRouter.backToRoot` 同樣先 dismiss presented 畫面再 `popToRootViewController`，方法註解寫明「含收掉 modal，目前只有 deeplink 使用」。驗證：同 1.1 的測試方式，斷言 completion 後無 presented 畫面且堆疊只剩根部；既有測試全數通過。[after: 1.1]

## 2. 模擬器驗證

- [x] 2.1 在模擬器手動重現原缺陷步驟並確認已修正：開「3 天內到期」清單 sheet → `xcrun simctl openurl <udid> foodentropy://item/<另一桶食材 uuid>` → 作者點確認框「打開」→ sheet 已關、編輯頁可見；另以「清單 sheet 內已推入編輯頁」、隱私權政策 sheet、`foodentropy://home`、已刪除食材的 uuid 各做一次，結果符合 navigation 規格的例子表。驗證：截圖記錄。[after: 1.2]
