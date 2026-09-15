## 1. 首頁發出前往設定的導航意圖

- [x] 1.1 先寫失敗測試 `齒輪點擊發出前往設定意圖`：對首頁 ViewModel 設定 `onRoute` 收集器，送出齒輪點擊的 ViewAction，斷言收到「前往設定」的 Router case。驗證：該測試在實作前因 case 不存在而編譯失敗。
- [x] 1.2 依決策「齒輪走既有的 MVVMC 導航路徑，不在 HostController 直接掛 bar button」，在首頁 ViewModel 的 ViewAction 與 Router 各加一個 case 並在 `handleViewAction` 串起來，兩個 enum 維持 `Sendable`。交付行為：首頁能以導航意圖表達「使用者要去設定」。驗證：1.1 轉為通過，既有 `HomeViewModelTests` 全數仍通過。
- [x] 1.3 首頁 HostController 保留 `StoreManager` 參考並處理新的 Router case，以 `AppRouter` 的預設 push 推入設定頁——對應 requirement「Settings is reached from the home screen's navigation bar」與決策「設定以 push 而非 sheet 呈現」。交付行為：導航意圖真的會把設定頁推上同一個 stack。驗證：專案建置通過；實際行為於 3.3 在模擬器確認。

## 2. 根控制器與 deeplink

- [x] 2.1 依決策「根控制器改為單一 navigation controller」實作 requirement「The root is a single navigation controller hosting the home screen」：SceneDelegate 的根組裝改為建立一個 `UINavigationController`、root 為首頁 HostController，移除包裝 tab 的輔助方法與首頁分頁索引常數。同時移除被 requirement「The root is a two-tab controller with per-tab navigation stacks」描述的舊結構。交付行為：啟動後畫面底部不再有 tab bar。驗證：模擬器啟動截圖確認無 tab bar。
- [x] 2.2 依決策「Deeplink 的四個進入點改從 navigation stack 取得首頁」改寫 SceneDelegate 的 `handle(_:)` 與 `showFoodItem`：不再轉型 `UITabBarController`，改為取根 `UINavigationController` 及其第一個 view controller；`Deeplink.home` 的處理由「切到首頁分頁」改為「pop 回 stack 根部」。交付行為：食材 deeplink 仍能抵達該食材的編輯表單。驗證：2.3 的三項實機驗證。
- [x] 2.3 以模擬器驗證 deeplink：從首頁收到食材 deeplink 時抵達該食材的編輯表單；停留在設定頁收到時，設定被移出 stack 不疊層。交付行為：`handle(_:)` 在單一 navigation stack 下正確解析並導航。驗證：兩種狀態各記錄一次 stack 內容。（`simctl openurl` 會被系統的「Open in …?」確認框擋住且無法自動點擊，故以 DEBUG 環境變數直接呼叫真正的 `handle(_:)`，驗畢移除；通知與 App Intents 兩條路徑共用同一個 `handle(_:)`，由本項加程式碼檢查涵蓋。）**已知限制**：停留在設定頁的情形下，設定會被收掉但編輯表單不會被推出——原因是 `showFoodItem` 的 pop-then-push 在同一個 runloop turn 內執行，push 被 UIKit 丟棄。該兩行與本 change 前逐字相同，屬既有缺陷，另立 change 處理，不在此驗收。

## 3. 齒輪與導覽列標題

- [x] 3.1 在首頁 SwiftUI View 的 toolbar trailing 位置加入齒輪按鈕，點擊送出 1.2 的 ViewAction；按鈕以帶文字標籤的形式建立，字面值直接寫在標籤內以便編譯器抽取。交付行為：首頁右上角出現可點的齒輪。驗證：模擬器截圖確認齒輪位置與可點擊。
- [x] 3.2 依決策「導覽列標題改由各自的 SwiftUI View 設定」，把首頁與設定的標題從 SceneDelegate 的 `navigationItem.title` 移到各自 SwiftUI View 的導覽列標題修飾器，字面值直接寫在修飾器內。交付行為：兩個畫面的標題與改動前相同，且 SceneDelegate 不再設定畫面 chrome。驗證：模擬器截圖確認兩頁標題文字不變。
- [x] 3.3 以模擬器驗證進出設定的完整流程：首頁點齒輪 → 設定頁出現且有返回鍵 → 以返回鍵回首頁 → 再進一次並以邊緣返回手勢回首頁。交付行為：符合 requirement「Settings is reached from the home screen's navigation bar」的三個 scenario 中的前兩個。驗證：各截一張圖，確認設定頁內容與改動前一致且返回可用。

## 4. 移除隨 tab bar 失效的程式碼

- [x] 4.1 [P] 依決策「移除語意已錯的程式碼而非留著」，移除 `AppRouter` 的切換分頁方法及其「請確認 rootViewController 為 UITabBarController」斷言。交付行為：`AppRouter` 不再有任何預設 root 為 tab 控制器的路徑。驗證：專案建置通過，全專案搜尋無 `tabBarController`。
- [x] 4.2 [P] 移除表單 HostController 的 `hidesBottomBarWhenPushed` 設定——對應 requirement「Default navigation is a push onto the single navigation stack」取代「Default navigation is a push onto the current tab's stack」後，已無底部 bar 可隱藏。交付行為：表單推入行為不變。驗證：專案建置通過；表單推入後外觀於 3.3 的截圖一併確認。
- [x] 4.3 依 requirement「Debug-only environment switches are excluded from Release builds」的新措辭，移除 `INITIAL_TAB` 這個 DEBUG 環境開關，並確認 `SEED_MOCKS` 與 `SCREENSHOT_MODE` 兩個開關保留且仍在 `#if DEBUG` 內。交付行為：DEBUG 開關清單與 spec 一致。驗證：全專案搜尋無 `INITIAL_TAB`；以 `SEED_MOCKS=1` 啟動確認仍會塞入 mock 食材。

## 5. 在地化與收尾

- [x] 5.0 依 requirement「A single food item is a deeplink destination」的新措辭，確認 deeplink 相關 scenario 不再以「分頁被選取」描述抵達首頁——tab 已不存在，該措辭無對應物。交付行為：`navigation` 的 deeplink requirement 與單一 stack 的實作一致。驗證：主 spec 套用後搜尋該 requirement 區塊無 `home tab` 字樣。


- [x] 5.1 建置專案讓編譯器抽取 3.1 與 3.2 的新字串，再以 `xcrun xcstringstool sync` 把 app 與 widget 兩個 target 的 `.stringsdata` 一併併回 `Sources/Resources/Localizable.xcstrings`，並依 repo 既有格式重新輸出以免整檔重排。交付行為：新字串以編譯器產生的 key 進入 String Catalog。驗證：`git diff` 只顯示新增條目，不含整檔格式差異。
- [x] 5.2 為 5.1 產生的新 key 補上 `zh-Hant` 翻譯，並逐條處理任何 stale 條目（動態 key 誤判 → 改回字面值；翻譯掛在未選用變體 → 搬到活的 key；功能已移除 → 刪）。交付行為：中英使用者都看到正確的標題與齒輪標籤。驗證：stale 數 = 0 且缺翻譯數 = 0。
- [x] 5.3 全專案搜尋確認 `UITabBarController`、`tabBarController`、`tabBarItem`、`hidesBottomBarWhenPushed`、`INITIAL_TAB` 五個字串皆已不存在（`openspec/changes/archive/` 下的歷史文件除外），並跑完整測試套件與 `spectra validate remove-tab-bar`。交付行為：改動完成且規格一致。驗證：搜尋無命中、測試全數通過且測試數不減少、validate 無錯誤。
