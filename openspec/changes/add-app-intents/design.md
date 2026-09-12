## Context

食熵 v1.2.0 的所有動作只能在 app 內操作。App Intents 讓同一批動作能從捷徑、Spotlight 與 Siri 觸發，且 iOS 27 起 App Intents 是 Siri 呼叫第三方 app 的唯一途徑（SiriKit 已棄用；本專案從未實作 SiriKit，因此沒有遷移負擔）。

既有基礎對本 change 有利：`persistence` 的 `SwiftDataManager` 已提供完整 CRUD（`create` / `update` / `markConsumed` / `markWasted` / `delete` / `fetchActiveFoods`），其 `save()` 已會呼叫 `WidgetCenter.shared.reloadAllTimelines()`，因此 Intent 改動資料後 `widget` 自動刷新，不需額外處理。

限制條件來自憲章與既有 capability：部署基準 iOS 26、Swift 6 strict concurrency、MVVMC 分層、`@Model` 不得離開 `persistence`、所有使用者可見字串走 String Catalog。

## Goals / Non-Goals

**Goals:**

- 食材的五個核心動作（新增／已使用／丟棄／延長／開啟）可從捷徑與 Spotlight 觸發，不需開啟 app。
- 食材可被 Siri 以自然語言開啟（`.system.open`）。
- Siri 能解析使用者指著畫面說的「這個」，以及到期通知對應的食材。
- 部署基準維持 iOS 26；iOS 27 專屬能力以 `@available` 包覆，iOS 26 裝置行為不變。

**Non-Goals:**

- 不重寫任何業務邏輯——Intent 一律呼叫 `persistence` 既有方法。
- 不拉高部署基準至 iOS 27。
- 不為「新增食材」尋找自然語言路徑——iOS 27 SDK 的 22 個 schema domain 皆無庫存／購物概念，新增僅能經捷徑與 Spotlight 觸發（見 proposal 的前提確認結果）。
- **不採用 `.system.searchInApp`**（2026-09-11 定案）：其協定 `ShowInAppSearchResultsIntent` 的契約是「開啟 app 並**顯示**搜尋結果」，而首頁沒有搜尋介面。採用會讓 Siri 開啟 app 卻顯示未經篩選的完整清單——使用者問了牛奶卻看到全部食材，比不提供更糟。要正確採用得先為 `home-ui` 補上搜尋介面與 `navigation` 的 `Deeplink.search`，那是獨立的產品決定，不由本 change 夾帶。搜尋改以回傳結果值的 `FindFoodItemsIntent` 提供，捷徑與 Spotlight 立即可用且不綁 iOS 版本，代價是拿不到 Siri 的自由語句搜尋。
- 不涵蓋 `widget` 的互動化（Widget 目前刻意不含互動，屬另一個未決項目）。
- 不實作 `OwnershipProvidingEntity`——食熵的資料沒有共享／多人概念，entity 恆為私有。
- 不做無障礙驗證（憲章明列非目標）。

## Decisions

### 決策一：Intent 在無 scene 的情況下執行，改用 process 層級的 SwiftDataManager

**問題**：`SwiftDataManager` 目前只在 `SceneDelegate.scene(_:willConnectTo:)` 內建立並由其持有。App Intents 的 `perform()` 可能在 app 未啟動、或啟動至背景而無 scene 時執行，此時取不到那個實例。

**決定**：在 `SwiftDataManager` 上新增 process 層級的共用取用點（`@MainActor static let`，沿用既有的 `makeResilient(cloudKitEnabled:)` 三層降級與 `AppPreferenceKey.iCloudSyncEnabled` 偏好讀取），`SceneDelegate` 改為取用它而非自行建立。

**替代方案與否決理由**：
- *讓 Intent 各自建立 `SwiftDataManager`*——同一 process 內會出現兩個 `ModelContainer` 指向同一份 store，Intent 的寫入不會反映到 app 既有 context，造成畫面與資料不一致。否決。
- *所有 Intent 設 `openAppWhenRun = true`*——等於每個動作都得開 app，捨棄 App Intents 最主要的價值。僅 `OpenIntent` 保留此行為（由框架預設提供）。否決作為通則。

`icloud-sync` 的「opt-in、預設關、下次啟動生效」語意不受影響：共用取用點在首次存取時才讀偏好，而 process 生命週期即為「一次啟動」。

### 決策二：AppEntity 與既有型別的命名與轉換

`persistence` 已有名為 `FoodItemEntity` 的 SwiftData `@Model`。App Intents 的 entity 必須另行命名為 `FoodItemAppEntity`，避免同名衝突。

分層不變：`FoodItemEntity`（`@Model`）→ `toDomain()` → `FoodItem`（Domain Model）→ `FoodItemAppEntity`。App Intents 層只接觸 `FoodItem`，**不得持有 `@Model`**，與 ViewModel／State 的既有規則一致。

`FoodItemAppEntity` 的 `id` 沿用 `FoodItem.id`（`UUID`），是穩定持久識別碼，滿足螢幕感知標註與 Spotlight 索引對 persistent identifier 的要求。

### 決策三：六個 Intent 與 schema 的對應

| Intent | schema | 開啟 app | 對應的既有方法 |
| --- | --- | --- | --- |
| `AddFoodItemIntent` | 無（無可用 domain） | 否 | `create(name:purchaseDate:expiryDate:imageData:price:)` |
| `MarkFoodConsumedIntent` | 無 | 否 | `markConsumed(id:)` |
| `MarkFoodWastedIntent` | 無 | 否 | `markWasted(id:)` |
| `ExtendFoodExpiryIntent` | 無 | 否 | `update(id:name:purchaseDate:expiryDate:imageData:price:)` |
| `OpenFoodItemIntent` | `.system.open`（iOS 27） | 是 | 經 `navigation` 的 `Deeplink` 進入首頁 |
| `FindFoodItemsIntent` | 無（見下） | 否 | `fetchActiveFoods()` 後以名稱篩選 |

`OpenIntent` 由框架提供 `openAppWhenRun` 與預設 `perform()`，只需宣告 `var target: FoodItemAppEntity`。

`ExtendFoodExpiryIntent` 必須傳入既有的 `name` / `purchaseDate` / `imageData` / `price` 再呼叫 `update`——`update` 刻意不給 `price` 預設值，避免呼叫端靜默清空既有價格（`persistence` 既有註釋已載明此陷阱）。

Intent 的 `perform()` 標為 `@MainActor` 以對齊 `SwiftDataManager` 的隔離；`AppIntent.perform()` 是 async 需求，允許由 actor-isolated 實作滿足，不需 `MainActor.run` 包覆。

### 決策四：iOS 27 專屬能力以 @available 包覆，部署基準不變

`.system.searchInApp`、`.system.open`、`UNMutableNotificationContent.appEntityIdentifiers` 皆為 iOS 27.0+。`@AppIntent(schema:)` 是型別層級的 macro，無法在單一型別內做條件編譯，因此**兩個 schema-based Intent 整個型別以 `@available(iOS 27.0, *)` 宣告**，並在 `AppShortcutsProvider` 的 `appShortcuts` 內以 `if #available` 分支加入。

iOS 26 裝置的行為：四個非 schema Intent 全部可用（捷徑／Spotlight），搜尋與開啟的 Siri 自然語言不可用，通知不帶 entity 標註。無崩潰、無降級提示。

### 決策五：螢幕感知標註掛在首頁清單與食材列

`.appEntityIdentifier` 自 iOS 18.4 起可用，低於本專案部署基準，**不需 `@available` 包覆**。

掛載點：**逐列標註真正的食材列**，在 `HomeView` 的 `BucketSection.row(_:)` 上以 `.appEntityIdentifier(_:)` 綁定該筆的 `EntityIdentifier`。

**不使用 `.appEntityIdentifier(forSelectionType:)` 掛在整個 `List` 上**（2026-09-11 實機 log 修正）：首頁的 `List` 前兩列是甜甜圈與浪費統計，並非食材。整列掛載會讓系統向它們一併索取 identifier，映射不到 `FoodItem.ID` 即回報 `Missing id for collectionItem`，並使 `UICollectionView Item AppIntents Payload` 的 async task 逾時（實測逾期 3.2 秒）。後果不只是 log 噪音——payload 逾時等於 Siri 拿不到可解析的螢幕內容，螢幕感知反而失效。

**標註寫在 `HomeView` 而非共用的 `FoodRowView`**：後者由 `widget` target 一併編譯，在其中引用 `FoodItemAppEntity` 會把 AppIntents 與整套 entity 定義拖進 extension，換來的卻是 Widget 情境下用不到的標註（Widget 不是 app 內畫面，Siri 的螢幕感知不經由它解析食材）。`HomeView` 不在 Widget 的來源清單內，在其 `row(_:)` 掛載即可兼顧兩者。

標註本身不改變任何視覺呈現，iOS 26 裝置上為無效果的 no-op（API 存在但無 Siri AI 消費）。

### 決策六：到期通知帶上 entity 標註

`notification` 目前為每項食材排一則通知。在 `UNMutableNotificationContent` 上加入 `appEntityIdentifiers`（iOS 27+，以 `@available` 包覆），值為該食材的 `EntityIdentifier`。

效果：使用者看到到期通知時，對 Siri 說「這個延長三天」可被解析到正確食材。既有的 `deeplink` payload 慣例與排程對帳邏輯不變。

### 決策七：食材進入 Spotlight 語義索引

`FoodItemAppEntity` 採用 `IndexedEntity`（iOS 18.0+，低於部署基準），提供 `attributeSet: CSSearchableItemAttributeSet`（標題為食材名稱、內容描述含到期日與狀態）。

索引時機：`SwiftDataManager` 的資料變動點統一觸發重新索引，與既有的 `WidgetCenter.shared.reloadAllTimelines()` 同一處，避免新增第二條「資料變了要通知誰」的路徑。

不採用 iOS 27 的 `IndexedEntityQuery`——它解決的是系統要求重新索引時的回填，對本專案資料量（個人庫存，數十筆）沒有實益。

### 決策八：Intent 改動資料後的畫面同步

**問題**：`HomeView` 目前只在 `.onAppear` 觸發重新載入。app 停留在背景時被 Intent 改動資料，回到前景不會重新觸發 `.onAppear`，清單將顯示過期內容。

**決定**：兩個觸發來源，皆送既有的 `.view(.onAppear)` ViewAction。不新增 Action case、不改 ViewModel，維持 mvvmc-view 的單向資料流。

1. `SwiftDataManager.didChangeNotification`——由寫入的單一出口 `save()` 廣播，與 `WidgetCenter` 刷新、Spotlight 重新索引同一處（決策七的同一個「資料變了要通知誰」出口）。App Intents 與畫面同在 app process，in-process 的 NotificationCenter 即足夠。
2. `UIApplication.didBecomeActiveNotification`——涵蓋 app 不在前景時發生的變動（含 CloudKit 於背景帶回的遠端變更）。

**兩次實機修正（2026-09-11）**，兩者都只有真機跑得出來：

- **`@Environment(\.scenePhase)` 不送達**：食熵是 UIKit 生命週期（`AppDelegate` + `SceneDelegate` + `UIHostingController`），不是 SwiftUI `App`。實測以捷徑在背景標記食材後切回前景，`onChange(of: scenePhase)` 未觸發，清單仍顯示已處理的食材，必須滑掉重開才更新——寫入本身成功，失效的只有觸發機制。改用 `UIApplication` 的通知，不依賴 SwiftUI 的場景環境。
- **前景 Spotlight 沒有生命週期轉換可依附**：iOS 27 可在 app 前景直接下拉 Spotlight 並執行動作，全程不離開前景，因此 `didBecomeActive` 不會送出。這是加上資料層廣播（來源 1）的原因，也是它成為主要觸發來源、生命週期通知退為補充的原因。

### 決策九：Intent 標題與 Siri 語句走 String Catalog

Intent 的 `title`、參數摘要與 `AppShortcut.phrases` 皆為使用者可見字串，一律以英文字面值寫在程式碼內並由 build 抽取至 String Catalog，再補 `zh-Hant` 翻譯（`localization` 既有規則）。

`AppShortcut.phrases` 必須包含 `\(.applicationName)`，且每個語言各自需要可唸出的語句——繁中語句在繁中 Siri AI 開通前不會被使用，但仍須提供，否則該語言的捷徑列表顯示為空。

### 決策十：開啟動作放棄 `.system.open`，換取全版本的 detail 導航

**問題**：`OpenFoodItemIntent` 原本掛 `.system.open` schema，因此整個型別被 `@available(iOS 27.0, *)` 鎖住，且使用框架預設的 `perform()`——效果只是把 app 打開停在首頁，並未前往指定食材。其描述字串寫著「Opens FoodEntropy showing a food item」，與實際行為不符。

同一個 Intent 也是 **Spotlight 點擊食材結果**時系統所呼叫的對象，因此該缺陷同時表現在兩處：Siri 說「開啟某食材」與 Spotlight 點擊，都只會停在首頁。

**決定**：拿掉 schema，改為直接conform `OpenIntent`（iOS 16+），並自訂 `perform()` 把目標轉成 `Deeplink.foodItem(id)` 的 URL 後交給既有的 URL 進入點。

**權衡**：

| | 保留 schema | 拿掉 schema（採用） |
| --- | --- | --- |
| Spotlight 點擊進 detail | 僅 iOS 27 | iOS 26 與 27 皆可 |
| Siri 以固定語句開啟 | 可 | 可（`AppShortcut` 語句不綁 schema） |
| Siri 自由語句理解 | 可 | 不可 |

schema 的獨家收益是自由語句理解，而那需要 Siri AI——英文限定、繁中未公布日期，且實機測試顯示參數綁定當時尚未生效。用「每天都會用到、全版本可用的 Spotlight 點擊」去換它並不划算。

> 未經查證的一點：`.system.open` 是否另有助於 Siri AI 認得「此 app 有可開啟的項目」，文件未明說，故不計入權衡。

**導航路徑**：Intent 不自行操作 view controller，而是產生 URL 走 `scene(_:openURLContexts:)`——`navigation` 要求所有進入點收斂到同一份 `Deeplink`，新增 detail 目標正是該檔註釋預留的擴充點。

### 決策十二：Siri 的自由語句需要兩個 system schema 成組，而前提是首頁搜尋介面

**實機發現（2026-09-12）**，用 Siri App 打字測試（排除語音辨識變數）：

| 輸入 | Siri 回應 |
| --- | --- |
| `show Test Milk in FoodEntropy` | 「I can't search for "Test Milk" in FoodEntropy because **the app doesn't support in-app search**.」 |
| `go to Test Milk in FoodEntropy` | 開啟 app 但停在首頁（Siri 內建動詞接手） |
| `open Test Milk in FoodEntropy` | 「I can't open "Test Milk" directly because FoodEntropy **doesn't support searching or opening specific items** within the app」 |

**結論**：Siri 要開啟「某一筆」，得先能「找到」那一筆；找到靠 `.system.searchInApp`。兩個 schema 實質上是一組，單獨採用 `.system.open` 沒有作用。

這同時解釋了先前所有觀察：
- 尚未移除 `.system.open` 時（2026-09-11 22:57）同樣失敗——有「開啟」但沒有「搜尋」。
- `MarkFoodConsumedIntent` 叫得到且跳出 entity 清單——它走**固定語句**，不需要自由搜尋，消歧由本專案的 `EntityQuery` 提供。
- Spotlight 點擊食材進 detail 完全正常——那條路不經過 Siri 的搜尋理解。

**對決策十的影響**：拿掉 `.system.open` 沒有額外損失。它單獨存在本來就無法讓 Siri 開啟特定食材，而換到的是 Spotlight 點擊在 iOS 26 也能進 detail。決策十維持。

**要取得 Siri 自由語句的唯一路徑**：先為 `home-ui` 補上搜尋介面、為 `navigation` 補上 `.search(String)` 目標，然後兩個 schema 一起採用。那是獨立的產品決定，不由本 change 夾帶——且搜尋功能本身對庫存清單有獨立價值，並非只為 Siri 而做。

### 決策十一：不開 app 的動作必須回報結果

**問題**：四個核心動作 `openAppWhenRun = false`，執行完不會把 app 帶到前景。原本一律回 `.result()`——Siri 不說話、畫面不顯示任何東西，使用者說完「mark this as used」後無從判斷成功與否，只能自己開 app 檢查。那等於抵銷了「不必開 app」的價值。

**決定**：四個動作改為同時回 `ProvidesDialog`（給語音）與 `ShowsSnippetView`（給畫面）。dialog 交由 Siri 唸出；snippet 是一張小卡，顯示動作符號、食材名稱，以及一行結果說明。

呈現資料全部取自已有的 `target`（`FoodItemAppEntity` 已帶 `name` 與 `expiryDate`），**不額外查資料庫**。延長效期顯示的是**新的**到期日——使用者要確認的正是改對了沒有。

**分工**：`ProvidesDialog` 管語音、`ShowsSnippetView` 管視覺，兩者分開宣告。純語音裝置（如 AirPods）只會得到 dialog，因此 dialog 本身必須自成完整句子，不能依賴 snippet 補充資訊。

**`FindFoodItemsIntent` 不加 dialog**：它是查詢而非動作，結果本身就是回傳值（捷徑會直接顯示）。加上 dialog 還會引入「找到 1 個項目」的單複數問題，而 String Catalog 的複數變體對這個收益不值得。

**不重用 `FoodRowView` 當 snippet**：那是清單列，帶滑動操作的觸控區與列高假設，且由 `widget` target 一併編譯。snippet 只需要「動作 + 食材 + 一行結果」，另寫一個更小的 view 更誠實。

## Implementation Contract

**行為**：

- 使用者在「捷徑」app 中可找到食熵的六個動作，設定參數後執行，資料寫入與 app 內操作等價。
- 在 Spotlight 輸入食材名稱可找到該食材並直接執行動作。
- 裝置語言為英文且 Siri AI 啟用時，對 Siri 說 "Search for milk in FoodEntropy" 可得到搜尋結果；說 "Open milk in FoodEntropy" 可開啟 app 並定位首頁。
- app 未執行時觸發非 `OpenIntent` 的動作，app 不會被帶到前景，資料仍正確寫入，Widget 於下次刷新反映結果。

**介面 / 資料形狀**：

- `FoodItemAppEntity`：`id: UUID`（取自 `FoodItem.id`）、`name`、`expiryDate`、`purchaseDate`、`price`、以及由 `ExpiryStatus.evaluate` 計算的狀態顯示。
- `AddFoodItemIntent` 參數：`name: String`（必填）、`expiryDate: Date`（必填）、`purchaseDate: Date`（選填，預設今天）、`price: Double?`（選填）。
- `ExtendFoodExpiryIntent` 參數：`target: FoodItemAppEntity`、`newExpiryDate: Date`。
- entity query 支援：依 `id` 取單筆、依字串篩選名稱、提供建議清單（`fetchActiveFoods()` 的結果）。

**失敗模式**：

- 找不到指定 entity（已被刪除或已離開 active）→ 拋出帶有本地化訊息的錯誤，不靜默成功。
- `SwiftDataManager` 的既有方法對不存在的 id 為靜默 no-op；Intent 層必須先行確認目標存在，將其轉為可見錯誤。
- store 建立失敗時沿用 `persistence` 既有的三層降級，Intent 不另行處理。

**驗收標準**：

- `xcodebuild build` 零 error 零 warning。
- 既有 81 個測試全數通過，且新增的 Intent 測試（依 `mvvmc-testing`：直接注入結果，不用 protocol／mock class）通過。
- 捷徑 app 中六個動作可見且可執行（手動驗證，步驟見 tasks 最後一組）。
- Siri 自然語言搜尋與開啟在 iPhone 15 Pro / iOS 27 / 英文語言下可用（手動驗證）。
- `Localizable.xcstrings` 的 stale 數為 0、缺 `zh-Hant` 翻譯數為 0。

**範圍邊界**：

- 範圍內：`Sources/Core/Intents/` 的新型別、`SwiftDataManager` 的 process 層級取用點、`NotificationService` 的 entity 標註、首頁與食材列的螢幕感知標註、`HomeView` 的前景重載、String Catalog 的新字串、capability map 更新。
- 範圍外：任何既有業務邏輯的修改、Widget 互動化、部署基準調整、新增第三方相依、無障礙相關工作。

## Risks / Trade-offs

- **[Siri AI 首發僅英文，繁中無日期]** → 繁中使用者短期只拿得到捷徑與 Spotlight（兩者不受語言限制）。程式碼先就位，繁中 Siri AI 開通後自動生效，不需再發版。此為上線時間差，非功能缺口。
- **[schema-based Intent 只能整個型別標 `@available(iOS 27.0, *)`]** → iOS 26 裝置的捷徑列表少兩個動作。可接受：這兩個動作（搜尋／開啟）在 iOS 26 上本就沒有 Siri 消費端。
- **[process 層級的共用 `SwiftDataManager` 改變了 `app-shell` 的 composition root 慣例]** → 僅新增取用點，建立邏輯（`makeResilient` 三層降級）與偏好讀取完全沿用；`SceneDelegate` 的 DEBUG 種子資料邏輯保留在原處，作用於共用實例。
- **[Intent 在背景寫入，app 前景顯示過期資料]** → 由決策八處理。
- **[Spotlight 索引與資料變動的耦合點集中在 `SwiftDataManager.save()`]** → 該處已負責 Widget 刷新，再加一項索引更新會讓 `persistence` 承擔更多「對外通知」職責。取捨：集中一處仍優於散落多個呼叫端而漏掉其一。
- **[App Intents API 在 iOS 27.0 為首發版本]** → `.system.searchInApp` 等 schema 首度公開，行為可能在 27.x 微調。緩解：schema-based 的兩個 Intent 與其餘四個解耦，即使行為有變也不影響捷徑與 Spotlight。

## Open Questions

- `.system.searchInApp` 的搜尋結果呈現由系統決定或由 app 提供 snippet view，需於實作時以實機確認；若系統要求 snippet，補 `ShowsSnippetView`。
- 繁中 Siri AI 的開通日期未公布，無法預先驗證繁中語句的辨識率。
