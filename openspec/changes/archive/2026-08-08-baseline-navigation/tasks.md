## 1. Baseline 文件化

- [x] 1.1 從三個 HostController 的 `viewDidLoad` + `handleRouter` 與各 ViewModel 的 `onRoute` 宣告，寫出 requirement「ViewModels emit navigation intent; HostControllers execute it」；驗證：`grep -rn "var onRoute" Sources/Features` 三個 feature 各命中一次，且 `grep -l "import UIKit" Sources/Features/*/[A-Za-z]*ViewModel.swift` 無結果。
- [x] 1.2 從 `AppRouter` 的類別宣告與各方法的 `guard let nav = source.navigationController` 寫出 requirement「AppRouter is a stateless main-actor singleton that derives context from the source」；驗證：`AppRouter` 除 `static let shared` 外無儲存屬性，且 `grep -rn "pushViewController\|\.present(\|\.dismiss(" Sources/Features` 僅命中 `FoodFormView.swift` 內 `UIImagePickerController` delegate 回呼的兩處 `picker.dismiss`——系統選擇器自行關閉，依 spec 明列為豁免，非畫面導航。
- [x] 1.3 從 `to(_:from:style:animated:)` 的 `style: TransitionStyle = .push` 預設值與兩處呼叫端寫出 requirement「Default navigation is a push onto the current tab's stack」；驗證：`grep -rn "AppRouter.shared.to" Sources` 的兩處皆未傳 `style:` 參數，且 `FoodFormHostController` 內設有 `hidesBottomBarWhenPushed = true`。
- [x] 1.4 從 `appTransitionStyle` associated object 與 `back(from:animated:)` 的樣式判斷寫出 requirement「The arrival transition is recorded on the destination so back resolves pop versus dismiss」；驗證：`to()` 與 `sheet()` 皆對 `destination.appTransitionStyle` 賦值，`back()` 內可見 `.sheet` → `dismiss` / 其餘 → `popViewController` 的分流，且 getter 的預設值為 `.push`。
- [x] 1.5 從 `sheet(_:from:detents:animated:)` 與 `SettingsHostController` 的隱私權政策分支寫出 requirement「Modal web content is shown as a page sheet」；驗證：`sheet()` 內設 `modalPresentationStyle = .pageSheet`，且 `SettingsHostController` 以 `SFSafariViewController` 為目的地呼叫它。
- [x] 1.6 從 `gestureRecognizerShouldBegin` 與 `to()` 內的手勢裝配寫出 requirement「The interactive back gesture is enabled only for the default push transition」；驗證：該方法同時檢查 `nav.viewControllers.count > 1` 與 `topViewController?.appTransitionStyle == .push`，且 `to()` 內對 `interactivePopGestureRecognizer` 與 iOS 26 的 `interactiveContentPopGestureRecognizer` 都指派了同一 delegate。
- [x] 1.7 從 `SettingsHostController` 的 `openNotificationSettings` 分支寫出 requirement「Leaving the app is not routed through AppRouter」；驗證：該分支使用 `UIApplication.shared.open` 且未經 `AppRouter`。
- [x] 1.8 從 `Deeplink.init?(url:)` 與 `SceneDelegate` 的三個進入點寫出 requirement「Deeplink parsing is centralised in one enum」；驗證：`grep -rn "url.scheme ==" Sources` 僅在 `Deeplink.swift` 命中；`SceneDelegate` 內 `handle(deeplink)` 被三處呼叫（`willConnectTo`、`openURLContexts`、`didReceive response`）；冷啟動分支位於 `makeKeyAndVisible()` 之後；通知分支的 payload 缺漏時回退 `foodentropy://home`。

## 2. 收尾

- [x] 2.1 執行 `spectra validate baseline-navigation` 確認四份 artifact 與 spec 格式通過；驗證：指令回傳成功、無 error。
- [x] 2.2 archive 後補上 `openspec/specs/navigation/spec.md` 的 `## Purpose` 段（CLI 會留下 TBD 佔位）；驗證：`grep -c "TBD" openspec/specs/navigation/spec.md` 為 0。
- [x] 2.3 建立 `openspec/specs/README.md` capability map，並於後續每批 baseline 補完時更新；驗證：檔案存在且列出目前已 archive 的所有 capability。
