## 1. 資料取用與 Entity 基礎

- [x] 1.1 讓沒有連上 scene 的進入點也取得到同一份 store：在 `SwiftDataManager` 加入 process 層級取用點（沿用 `makeResilient` 與 `AppPreferenceKey.iCloudSyncEnabled`），`SceneDelegate` 改為取用它而非自行建立，DEBUG 種子資料邏輯保留並作用於該實例。滿足 `The store is reachable from a process-level accessor`。驗證：新增單元測試斷言同一 process 內兩次取用為同一實例，且 `xcodebuild test` 既有 81 測試仍全過。（決策一：Intent 在無 scene 的情況下執行，改用 process 層級的 SwiftDataManager）

- [x] 1.2 食材可被助理辨識為一個實體：新增 `FoodItemAppEntity`，`id` 取自 `FoodItem.id`，攜帶名稱／購買日／到期日／價格與由 `ExpiryStatus.evaluate` 讀取時計算的狀態，且不持有 `@Model`。滿足 `Food items are exposed as an app entity with a stable identifier`。驗證：單元測試斷言由同一 `FoodItem` 轉出的 entity id 穩定、且 entity 型別不含 `FoodItemEntity`。（決策二：AppEntity 與既有型別的命名與轉換）

- [x] 1.3 助理能依 id、名稱與建議清單取得食材：實作 entity query，依 id 取單筆、依字串不分大小寫部分比對名稱、無條件時回傳 `fetchActiveFoods()` 結果。滿足 `Entity queries resolve by identifier, by name, and by suggestion`。驗證：單元測試涵蓋 spec 內的名稱篩選表格（milk／MILK／cheese 三列）與「已刪除 id 回傳空」。

## 2. 核心四動作

- [x] 2.1 四個動作不開 app 即可完成寫入：實作 `AddFoodItemIntent`、`MarkFoodConsumedIntent`、`MarkFoodWastedIntent`、`ExtendFoodExpiryIntent`，一律呼叫 `SwiftDataManager` 既有方法；`ExtendFoodExpiryIntent` 需帶回既有 `name`／`purchaseDate`／`imageData`／`price` 再呼叫 `update`，避免靜默清空價格。滿足 `Core food actions run without opening the app`。驗證：單元測試斷言延長效期後 price 與 imageData 不變（對應 spec 的 Milk／89.0 範例）。（決策三：六個 Intent 與 schema 的對應）

- [x] 2.2 目標不存在時回報錯誤而非假成功：在四個動作中先確認目標仍為 active，否則丟出本地化錯誤；`SwiftDataManager` 對不存在 id 的靜默 no-op 不得被當成成功。滿足 `Actions fail loudly when the target no longer exists`。驗證：單元測試斷言對已刪除與已 resolved 的目標各自丟錯且無寫入。

## 3. iOS 27 專屬的自然語言動作

- [x] 3.1 iOS 27 上可用語音開啟，iOS 26 上該動作不存在且其餘動作不受影響：以 `@available(iOS 27.0, *)` 宣告 `OpenFoodItemIntent`（`.system.open`），並在 `appShortcuts` 內以 `if #available` 分支加入。滿足 `Opening a food item by voice is available on iOS 27`。**`.system.searchInApp` 決定不採用**——其協定 `ShowInAppSearchResultsIntent` 的契約是「開啟 app 並顯示搜尋結果」，而首頁沒有搜尋介面；採用會導致 Siri 開啟 app 卻顯示未篩選的完整清單。搜尋改以 `FindFoodItemsIntent` 回傳結果值提供，不綁 iOS 版本。驗證：`generic/platform=iOS` 建置零警告，實機確認 `.system.open` 可由 Siri 觸發。（決策四：iOS 27 專屬能力以 @available 包覆，部署基準不變）

## 4. 系統整合表面

- [x] 4.1 [P] 食材可在 Spotlight 以名稱找到且狀態變動後即時反映：`FoodItemAppEntity` 採用 `IndexedEntity` 並提供 `attributeSet`（標題為名稱、描述含到期日與狀態），索引更新掛在 `SwiftDataManager` 既有的資料變動通知點（與 `WidgetCenter.reloadAllTimelines()` 同處）。滿足 `Food items are indexed for Spotlight`。驗證：實機在 Spotlight 搜尋新增的食材名稱可找到，標記已使用後不再出現在 active 結果。（決策七：食材進入 Spotlight 語義索引）

- [x] 4.2 [P] 助理能解析使用者指著畫面說的「這個」，且畫面外觀完全不變：首頁分桶清單以 `.appEntityIdentifier(forSelectionType:)` 標註（由 `FoodItem.ID` 映射），共用食材列元件另標註單一 entity；不加 `@available`（API 為 iOS 18.4，低於部署基準）。滿足 `On-screen food items are annotated for assistant resolution`。驗證：標註前後各截一張首頁截圖比對版面無差異。（決策五：螢幕感知標註掛在首頁清單與食材列）

- [x] 4.3 [P] 到期通知在 iOS 27 帶上對應食材、iOS 26 行為完全不變：於 `NotificationService` 建立 `UNMutableNotificationContent` 時以 `@available(iOS 27.0, *)` 加入 `appEntityIdentifiers`，既有 deeplink payload 與排程對帳邏輯不動。滿足 `Notifications carry a deeplink payload and are shown even in the foreground`。驗證：既有通知測試全過，並以 DEBUG 立即觸發模式確認通知仍正常送達。（決策六：到期通知帶上 entity 標註）

- [x] 4.4 [P] 背景被動作改動後回到前景，首頁顯示最新資料：`HomeView` 以 `@Environment(\.scenePhase)` 監看，回到 `.active` 時再送一次既有的 `.view(.onAppear)`，不新增 Action case、不改 ViewModel。驗證：手動以捷徑在 app 背景時標記已使用，回到 app 確認該列已消失。（決策八：Intent 改動資料後的畫面同步）

## 5. 在地化與曝露

- [x] 5.1 六個動作在捷徑 app 中以正確名稱出現、兩種語言各有可唸出的語句：實作 `AppShortcutsProvider`，每個動作的 `phrases` 含 `\(.applicationName)`，英文字面值直接寫在程式碼內由 build 抽取。滿足 `Assistant phrases and action titles are localized`。驗證：捷徑 app 內六個動作可見且名稱正確。（決策九：Intent 標題與 Siri 語句走 String Catalog）

- [x] 5.2 新字串全部有繁中翻譯且無 stale：build 後以 `xcstringstool sync` 併回 `Localizable.xcstrings`，依實際產生的 key 補 `zh-Hant`。驗證：以 Python 讀 catalog 斷言 stale 數為 0、缺 `zh-Hant` 數為 0（空字串 key 除外，該筆為既有的 Chart 軸標籤）。

## 6. 整合與驗證

- [x] 6.1 新檔案進入 Xcode 專案且專案可建置：新增 `Sources/Core/Intents/` 後執行 `xcodegen generate`。驗證：`xcodebuild -scheme FoodEntropy -destination 'generic/platform=iOS' build` 零 error 零 warning。

- [x] 6.2 既有行為未被破壞：執行完整測試。驗證：`xcodebuild test -destination 'platform=iOS Simulator,name=iPhone 18 Pro' CODE_SIGNING_ALLOWED=NO` 顯示既有 81 測試加上本 change 新增測試全數通過。

- [x] 6.3 捷徑與 Spotlight 的實機驗收：在 iPhone 15 Pro（iOS 27）上逐一執行六個動作，確認寫入結果與 app 內操作一致、非 `OpenIntent` 的動作不會把 app 帶到前景。驗證：作者依 tasks 提供的步驟實測並回報結果。

- [x] 6.4 Siri 的實機驗收：裝置語言英文 + Siri AI 啟用下完成。已確認：Siri 捷徑授權對話框列出全部六組語句、`.system.open` 可開啟 app、Siri 可叫用 Intent 並正確顯示 entity 消歧清單。**名稱綁定與螢幕感知未能驗證**——Siri AI 為首發 beta 且裝置索引未完成，作者判斷螢幕感知投報率過低，決定不再追查（見 app-intents spec：助理端的解析結果不列為驗收標準）。app 端的義務（標註存在、不改變版面、payload 不逾時）已由 log 確認達成。

- [x] 6.5 capability map 反映新增的能力：於 `openspec/specs/README.md` 加入 `app-intents` 並標註其與 `persistence`、`notification`、`home-ui`、`navigation` 的引用關係。驗證：內容審閱確認新條目與既有條目格式一致。
