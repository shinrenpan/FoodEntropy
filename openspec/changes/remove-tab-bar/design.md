## Context

現行根控制器是 `UITabBarController`，兩個 tab（Home、Settings）各自包一層 `UINavigationController`，由 SceneDelegate 這個唯一組裝點建立。`app-shell` 有一條 requirement 明文要求「exactly two tabs」，`navigation` 的預設導航 requirement 則寫成「push onto the current tab's stack」，並帶有一條「表單推入時隱藏 tab bar」的 scenario。

tab 控制器不只是外觀，它是導航的骨架：三個 deeplink 進入點（冷啟動 URL、熱啟動 URL、通知點擊）與 App Intents 放下的待處理目標，全部經由 SceneDelegate 的同一個 `handle(_:)`，而它的第一行就是把 `window.rootViewController` 轉型成 `UITabBarController`，轉型失敗即靜默返回。實際抵達食材的 `showFoodItem` 也從 tab 控制器取 `selectedViewController` 才拿得到 navigation stack。

這代表本次改動的風險不在視覺，而在**失敗不會叫**：deeplink 斷掉的表現就是「什麼都沒發生」，沒有崩潰、沒有 log、沒有測試會紅。

另有兩處會隨 tab bar 一起失去意義：`AppRouter` 的切換分頁方法（其斷言明文要求 root 是 `UITabBarController`，留著會反過來誤導人），以及表單 HostController 上的「推入時隱藏底部 bar」設定。`INITIAL_TAB` 這個 DEBUG 環境開關也一併消失，而它被 `app-shell` 的「DEBUG 環境開關不得進 Release」requirement 逐項點名。

## Goals / Non-Goals

**Goals:**

- 根控制器成為單一 `UINavigationController`，首頁為其 root。
- 設定由首頁導覽列右上角進入，以 push 呈現，標準返回鍵退回。
- 四個導航進入點（冷啟動 URL、熱啟動 URL、通知點擊、App Intents 待處理目標）行為與改動前完全相同。
- 隨 tab bar 失效的程式碼與 DEBUG 開關一併移除，不留下語意已錯的斷言。
- `app-shell`、`navigation`、`home-ui` 三份 spec 與實作一致。

**Non-Goals:**

- **不改首頁版面**。環形圖、浪費統計、三個分桶、空狀態、廣告位置、Add Food 按鈕全部維持現狀。底部拿回來的空間這次不重新分配。
- **不改設定頁的內容與互動**，只改它怎麼被抵達、以及標題由誰設定。
- **不改 `Deeplink` 的 URL 格式**。`foodentropy://home` 與 `foodentropy://item/<uuid>` 對外完全不變。
- 不改 `AppRouter` 的 push / sheet / deeplink 三個既有方法的行為。
- 不處理移除廣告內購因入口變深而降低曝光的問題。

## Decisions

### 根控制器改為單一 navigation controller

`window.rootViewController` 從 `UITabBarController` 換成一個 `UINavigationController`，其 root 為首頁 HostController。組裝仍然只發生在 SceneDelegate（`app-shell` 的「單一組裝點」requirement 不變）。

把 root 包成 tab 的輔助方法與首頁分頁索引常數隨之移除。`INITIAL_TAB` 這個用來指定初始分頁的 DEBUG 開關也移除——只剩一個畫面時它沒有對象。

`SEED_MOCKS` 與 `SCREENSHOT_MODE` 兩個 DEBUG 開關**保留**，它們與 tab 無關。

### 設定以 push 而非 sheet 呈現

設定頁以 `AppRouter` 的預設 push 推入首頁所在的 stack。

這是刻意選擇而非順手：sheet 在語意上更貼切（設定是岔路，不是內容階層的更深一層），但 push 在這個專案有三個具體優勢。

第一，push 是這個 app 既有的導航語彙——`navigation` 的預設 requirement 就是 push，`AppRouter` 的主路徑是 push，返回手勢與自訂轉場都是為 push 調校的；sheet 目前只用於「App 內開啟網頁」這一種情境。

第二，原本反對 push 的理由（設定與食材表單擠同一個 stack）已經有現成解：`showFoodItem` 在推入編輯表單前，若 stack 深度大於一就先 pop 回根。設定被推著時收到「開啟某食材」的 deeplink，這段會先把設定收掉再推表單——正是該有的行為，不需要為此改任何東西。

第三，push 只有一條路徑，不必處理 dismiss 與 pop 兩種返回語意。

### 齒輪走既有的 MVVMC 導航路徑，不在 HostController 直接掛 bar button

齒輪放在首頁 SwiftUI View 的 toolbar（trailing 位置），點擊送出一個 ViewAction，ViewModel 據此發出導航意圖，由首頁 HostController 交給 `AppRouter` 執行。

替代做法是在 HostController 直接設 `navigationItem.rightBarButtonItem`，少寫兩層。否決：`navigation` 有一條 requirement 明文要求「ViewModel 發出導航意圖、HostController 執行」，直接掛 bar button 會讓首頁多出一條繞過 ViewModel 的導航路徑，且該路徑無法被 ViewModel 測試涵蓋。表單畫面的取消／儲存鈕也已經是走 SwiftUI toolbar，此處比照。

首頁 HostController 因此需要持有 `StoreManager`——設定頁的建構需要它。目前首頁 HostController 收下 `store` 後只轉交給 ViewModel、自己不保留，需改為保留。

### 導覽列標題改由各自的 SwiftUI View 設定

目前首頁與設定的標題都由 SceneDelegate 設在 `navigationItem.title` 上。設定頁改由首頁建構後，SceneDelegate 不再認識它，標題必須有新的歸屬。

兩個畫面都改為在自己的 SwiftUI View 以導覽列標題修飾器設定，字面值直接寫在修飾器內由編譯器抽取。這與表單畫面既有的做法一致（它本來就自己設標題），也讓 SceneDelegate 只負責組裝結構、不負責畫面 chrome。

`app-shell` 原本「Tab 標題取自 String Catalog」的約束隨 tab 消失，改以導覽列標題同樣取自 String Catalog 表達。

### Deeplink 的四個進入點改從 navigation stack 取得首頁

`handle(_:)` 不再轉型 `UITabBarController`，改為直接取根 `UINavigationController`。`showFoodItem` 不再經由 `selectedViewController`，改為直接使用該 stack。

`Deeplink.home` 的語意由「切換到首頁分頁」變成「回到 stack 根部」——對使用者而言結果相同（看到首頁），但實作換了。深度大於一時 pop 回根，本來就是既有行為的一部分。

四個進入點（冷啟動 URL、熱啟動 URL、通知點擊、App Intents 待處理目標）**全部匯流到同一個 `handle(_:)`**，差別只在何時被呼叫。因此只要 `handle(_:)` 與 `showFoodItem` 在新結構下正確，四條路徑就都正確；驗證策略據此設計（見 Implementation Contract）。

### 移除語意已錯的程式碼而非留著

`AppRouter` 的切換分頁方法、首頁分頁索引常數、包裝 tab 的輔助方法、表單 HostController 的「隱藏底部 bar」設定，全部移除。

不採「留著但不呼叫」：切換分頁方法的斷言訊息明文寫著「請確認 rootViewController 為 UITabBarController」，在 root 已非 tab 控制器之後，那段文字會把未來讀到它的人導向錯誤結論。死碼配上錯誤的斷言訊息比死碼本身更糟。

## Implementation Contract

**行為（使用者可觀察）**

1. 啟動後直接看到首頁，畫面底部沒有 tab bar，首頁清單因此多出約一列的可用高度。
2. 首頁導覽列右上角有一顆齒輪；點擊後以 push 轉場進入設定頁，設定頁左上角為標準返回鍵，返回手勢可用。
3. 設定頁的內容、排版與所有互動（購買、iCloud 開關、通知列、隱私權政策、版本）與改動前完全相同。
4. 從設定頁返回首頁時，首頁重新載入其資料（沿用既有的「出現時重載」行為）。
5. 四個導航進入點行為不變：
   - `foodentropy://item/<uuid>` 在 app 未啟動時開啟 → 冷啟動並停在該食材的編輯表單。
   - 同一 URL 在 app 已在前景時開啟 → 推入該食材的編輯表單。
   - 點擊到期通知 → 抵達對應食材。
   - 捷徑／Siri／Spotlight 的「開啟某食材」 → 抵達對應食材。
6. 目標食材已被刪除或已處理時，停在首頁，不報錯（既有行為）。
7. 連續開啟不同食材，或在設定頁時收到開啟食材的 deeplink，都不會疊出多層畫面——先回到首頁。

   **已知限制（既有缺陷，不在本 change 範圍）**：回到首頁後，編輯表單不會被推出。`showFoodItem` 在同一個 runloop turn 內先 `popToRootViewController(animated: false)` 再 push，UIKit 會丟棄該次 push。這兩行與本 change 前逐字相同，2026-09-15 以受控實驗確認在不涉及設定頁的情形（連續兩個食材 deeplink）同樣重現，故屬 v1.3.0 即存在的缺陷，另立 change 修正。

**介面／資料形狀**

- `window.rootViewController` 的型別為 `UINavigationController`；其 `viewControllers.first` 為首頁 HostController。
- 首頁 ViewModel 的 Router enum 新增一個「前往設定」case；ViewAction enum 新增一個對應的點擊 case。兩者維持 `Sendable`。
- 首頁 HostController 保留 `StoreManager` 參考，用於建構設定頁。
- 首頁與設定的導覽列標題由各自的 SwiftUI View 設定，字面值為英文並由 build 抽取進 String Catalog。
- `Deeplink` enum、其 URL 解析與產生完全不變。
- `AppRouter` 的 push / sheet / deeplink 三個方法簽章與行為不變；切換分頁方法移除。

**失敗模式**

- 取不到根 navigation controller 時，`handle(_:)` 靜默返回（維持既有的靜默語意，不新增崩潰路徑）。
- 目標食材不存在時停在首頁，不顯示錯誤。
- `AppRouter` 推入時若 source 沒有 navigation controller，維持既有的 DEBUG 斷言。

**驗收標準**

- 新增首頁 ViewModel 測試：送出齒輪點擊的 ViewAction 後，ViewModel 發出「前往設定」的導航意圖。既有 `HomeViewModelTests` 全數維持通過。
- 完整測試套件通過，且既有測試數不得減少。
- 全專案搜尋不再出現 `UITabBarController`、`tabBarController`、`tabBarItem`、`hidesBottomBarWhenPushed`、`INITIAL_TAB` 任一字串（`openspec/changes/archive/` 下的歷史文件除外）。
- 模擬器實際驗證：啟動無 tab bar、齒輪可進設定、返回鍵與返回手勢可回首頁，各截一張圖。
- 模擬器實際驗證 deeplink：從首頁收到食材 deeplink 時抵達該食材的編輯表單；停留於設定頁時收到，確認設定被移出 stack。通知與 App Intents 兩條路徑與 URL 路徑共用同一個 `handle(_:)`，其正確性由上述驗證加程式碼檢查涵蓋，不另行手動觸發。上述第二種情形不驗「表單被推出」，理由見 Implementation Contract 第 7 點的已知限制。
- String Catalog：stale 數 = 0、缺翻譯數 = 0。

**範圍邊界**

- 範圍內：SceneDelegate 的根組裝與 deeplink 處理、`AppRouter` 的切換分頁方法移除、首頁的 View／ViewModel／HostController 三層、設定與首頁的導覽列標題歸屬、表單 HostController 的隱藏底部 bar 設定、String Catalog、首頁 ViewModel 測試，以及 `app-shell`／`navigation`／`home-ui` 三份 spec 的 delta。
- 範圍外：首頁版面與其任何元件、設定頁內容、`Deeplink` 的 URL 格式、`AppRouter` 其餘方法、Widget、通知服務、資料層。

## Risks / Trade-offs

- **[既有缺陷：deeplink 在有畫面推著時只會彈回首頁]** → 本 change 實作期間查出，非本次造成（pop-then-push 兩行與改動前逐字相同）。影響 Siri／通知／Spotlight 三條進入點。已從本 change 的驗收與 `home-ui` 的 scenario 中排除，另立 change 修正，以免「拿掉 tab bar 是否弄壞 deeplink」與它混為一談。
- **[deeplink 斷掉不會有任何徵兆]** → 這是本次改動唯一的實質風險：`handle(_:)` 與 `showFoodItem` 的失敗路徑都是靜默 return，沒有崩潰也沒有測試覆蓋。以模擬器實際開 URL 驗證冷啟動、熱啟動、以及停留設定頁三種狀態，並確認四條進入點共用同一個匯流函式。
- **[設定變深一層，移除廣告內購的曝光下降]** → 已知且接受。tab 標題「Settings」本來也不是有效的內購漏斗；真正的改善是在廣告橫幅旁給一個入口，那是獨立題目，不在本次範圍。
- **[首頁多一顆齒輪，導覽列右上角這塊地被佔用]** → 首頁目前右上角是空的，沒有競爭者。若日後需要其他動作（例如排序或篩選），屆時再處理擁擠問題。
- **[push 讓設定與表單共用同一個 stack]** → 既有的「推入表單前先 pop 回根」邏輯已涵蓋，不需新增程式碼；但該邏輯從此多擔負一個職責，已在本文件記錄，避免日後被當成多餘保護而刪掉。
- **[拿回的底部空間這次不使用]** → 刻意的。版面重新分配與本次的導航骨架改動混在一起，deeplink 若出問題將難以歸因。
