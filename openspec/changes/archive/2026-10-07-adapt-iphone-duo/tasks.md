## 1. 依賴與平台設定

- [x] 1.1 Keep the portrait declaration and require AdMob 13.11.0：`project.yml` 的 GoogleMobileAds 改為 `from: "13.11.0"`，`UISupportedInterfaceOrientations` 維持只有 Portrait。完成時重新產生專案並解析套件後，建置出的 app 內嵌 `GoogleMobileAds.framework` 的 `CFBundleShortVersionString` 為 13.11.0 以上，Info.plist 的方向仍只有 Portrait。驗證：`xcodegen generate` 後解析套件、clean build，以 `plutil -p` 讀取內嵌 framework 版本與 app Info.plist。注意全域 SPM 快取可能停在舊 tag，需先 fetch tags。
- [x] 1.2 The platform envelope is iPhone-only, portrait, iOS 26 or later：把 `CLAUDE.md` 與 `openspec/config.yaml` 的「portrait-locked」描述改為「一般 iPhone 與 iPhone Duo 外螢幕只支援直立；Duo 內螢幕不理會方向宣告，依可用空間排版」，與 `app-shell` delta spec 一致。驗證：內容審閱，`grep -n -i portrait CLAUDE.md openspec/config.yaml` 的每一處都包含 Duo 內螢幕的例外。

## 2. 廣告與 entitlement

- [x] 2.1 The banner takes its width from the layout, not from the ad SDK（Bridged banner sizes from the proposal）：`BannerAdView` 實作 `sizeThatFits(_:uiView:context:)`，回傳提案寬度與固定 banner 高度，提案寬度為 nil 或無限大時退回 banner 標準寬度；註解改寫為與容器種類無關的說明（不再提 ArrangementView）。驗證：在 iPhone Duo 模擬器內螢幕直向冷啟動後轉成橫向，廣告完整落在首頁欄內、未蓋到設定欄；並以 iPhone 18 Pro（iOS 27.0）確認廣告為 320×50 置中。
- [x] 2.2 Entitlement changes reach every visible screen（Announce entitlement changes）：`StoreManager` 在 `adsRemoved` 實際改變時發出 `StoreManager.didChangeNotification`，值相同時不發；首頁監聽它並重讀，使廣告位隨 entitlement 出現或消失。驗證：在 Xcode 以 `FoodEntropy.storekit` 執行，Duo 內螢幕橫向下從設定欄購買移除廣告，首頁廣告立即消失；於 Debug → StoreKit → Manage Transactions 刪除交易後廣告回來。既有 `HomeViewModelTests` 全數通過。

## 3. 設定頁

- [x] 3.1 All displayed state is reloaded each time the screen appears：`SettingsView` 除了出現時，也在 `UIApplication.didBecomeActiveNotification` 與 `StoreManager.didChangeNotification` 時重讀狀態。驗證：設定在左欄顯示時，到系統設定變更通知權限再回到 app，通知列即時更新；購買或刪除測試交易後購買列即時更新。既有 `SettingsViewModelTests` 全數通過。[after: 2.2]
- [x] 3.2 Compose settings inside the home host（設定導航共用與嵌入模式）：`SettingsHostController.handle(_:from:)`（static）執行 `SettingsViewModel.Router`，推入的設定頁與嵌入首頁的設定共用；`SettingsView(viewModel:isEmbedded:)` 在嵌入時不設定 `navigationTitle`。兩者以註解標明為已知架構債（MVVMC，2026-10-07）並指向改用容器的條件。驗證：推入的設定頁標題為「設定」、開隱私權政策 sheet 正常；嵌入時首頁標題維持「首頁」、從左欄開隱私權政策 sheet 正常。
- [x] 3.3 A pushed settings screen yields to the settings column（Pushed settings yields when the space widens）：被推入的 `SettingsHostController` 在 `viewWillTransition(to:with:)` 偵測新尺寸寬大於高時，於轉場完成後經 `AppRouter.back(from:animated: false)` 退回；註解更正為「設定並排在左欄」並標明判斷條件須與 `HomeRootView` 一致。驗證：Duo 外螢幕推入設定後翻開（半開與全開各一次）、內螢幕直向推入設定後轉橫，畫面都變成兩欄且只有一份設定。[after: 3.2]

## 4. 首頁並排版面

- [x] 4.1 Column boundary follows the fold：把欄寬計算寫成純值型別，輸入容器尺寸與可選的直向折線（矩形與是否啟用），輸出是否兩欄、左欄寬、間距、右欄寬；規則為窄空間單欄、折線啟用時讓出折線、未啟用時分界在折線中央、沒有折線或折線不在容器內時各占一半。驗證：新增單元測試涵蓋上述各情況，使用實測數值（容器寬約 867、高 553，折線 455–495：未啟用約 475／0／391，啟用約 455／40／371，畫面讀值為整數截斷，測試以 1pt 容差比對；容器 669×951 為單欄），新增測試檔後重跑 `xcodegen generate` 並確認測試數增加。
- [x] 4.2 A wide container shows settings beside the home screen（Lay out two columns with HStack and reserved regions；Measure the space given, not the content）：新增 `HomeRootView`，以 `GeometryReader` 量外層提案、套用 4.1 的計算，寬時 `HStack { SettingsView(isEmbedded: true); HomeView }`、兩欄都給確定寬度，窄時只有 `HomeView`；首頁固定在同一位置；折線空白與兩欄背景同色；以 `#available(iOS 27.1, *)` 讀 `reservedRegions(kind: .division, options: .includeInactive)`。`HomeHostController` 改以它為 root view、持有 `SettingsViewModel` 並以 `SettingsHostController.handle(_:from:)` 執行其導航。驗證：Duo 模擬器整圈手動驗證——外螢幕、半開、全開、內螢幕直向、直向→橫向、橫向→直向、全開↔半開；每一步兩欄位置正確、無偏移、首頁不重建（卡牌選中狀態保留）。[after: 3.2, 4.1]
- [x] 4.3 Settings is reached from the home screen's navigation bar（並排時不顯示設定按鈕）：`HomeView(viewModel:showsSettingsButton:)` 在 `showsSettingsButton == false` 時不放設定按鈕，`HomeRootView` 於兩欄時傳 `false`。驗證：Duo 內螢幕橫向無設定按鈕，轉回直向或闔上後按鈕回來；iPhone 18 Pro（iOS 27.0）始終有按鈕且沒有返回鈕。[after: 4.2]

## 5. 整體驗證

- [x] 5.1 全開時從左欄開隱私權政策 sheet 後闔上，sheet 仍存活並轉為外螢幕全螢幕 sheet，app 不崩潰；自訂彎曲角度下兩欄仍停在折線兩側。驗證：Duo 模擬器手動操作並截圖記錄。[after: 4.3]
- [x] 5.2 既有測試與新測試全部通過，String Catalog 無 stale、無缺翻譯。驗證：`xcodebuild test`（iPhone 18 Pro，iOS 27.0，`-testLanguage en`）全數通過；build 後執行 `xcstringstool sync`，stale 數與缺翻譯數皆為 0。[after: 5.1]
