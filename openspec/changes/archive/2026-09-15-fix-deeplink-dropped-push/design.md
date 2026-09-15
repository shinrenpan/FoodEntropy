## Context

`SceneDelegate` 的 `showFoodItem` 是四個導航進入點（冷啟動 URL、熱啟動 URL、通知點擊、App Intents 待處理目標）的共同終點。它目前在同一個 runloop turn 內先 `popToRootViewController(animated: false)`、再透過 `AppRouter` push 編輯表單。UIKit 在前一次導航尚未落定時會丟棄後續的 push，於是 pop 生效而 push 消失。

2026-09-15 以受控實驗確認（直接呼叫真正的 `handle(_:)` 並記錄 stack 內容）：

| 收到 deeplink 時的畫面 | 結果 stack |
| --- | --- |
| 首頁 | `[Home, FoodForm]` — 正確 |
| 已推著任一畫面 | `[Home]` — 表單消失 |

兩次走同一段程式碼，唯一差別是 stack 深度是否大於一，也就是那個 pop 有沒有被執行到。

`navigation` 的 requirement 早已規定正確行為（第二個 deeplink 的 detail 應**取代**前一個），所以這不是規格缺口而是實作缺陷。缺陷自 v1.0.0 起存在。

還有一個結構問題使這個缺陷得以存在：`popToRootViewController` 是**導航邏輯寫在 `AppRouter` 之外**。`navigation` 明文要求導航集中於 `AppRouter`、進入點不自帶導航邏輯，而這行正是反例——它繞過了唯一導航中樞，也因此躲過了中樞裡既有的轉場與手勢設定。

## Goals / Non-Goals

**Goals:**

- 不論收到 deeplink 時畫面上是什麼，都抵達目標食材的編輯表單。
- 抵達動作是原子的：不出現「先回到首頁、再彈出表單」的兩段跳動。
- 導航動作回到 `AppRouter` 內，`SceneDelegate` 不再自行操作 navigation stack。
- 該行為有單元測試守著，不再只能靠人工操作或截圖驗證。

**Non-Goals:**

- 不改 `Deeplink` 的 URL 格式與解析。
- 不改四個進入點各自的觸發時機，只改抵達之後的導航動作。
- 不改「目標食材已不存在時停在首頁且不報錯」的行為。
- 不加任何使用者可見的錯誤提示。
- 不改首頁版面、設定頁或資料層。
- 不改 `AppRouter` 既有的 push / sheet / deeplink 三個方法的行為。

## Decisions

### 以單次原子的 stack 設定取代「pop 後再 push」

在 `AppRouter` 新增一個方法，把「回到根部並呈現目標」表達成**一次** stack 設定，而不是兩次導航呼叫。UIKit 因此只看到一次轉場，沒有東西可以被丟棄。

替代方案是維持 pop 與 push 兩次呼叫，但讓 push 延到下一個 runloop turn。否決，兩個理由：其一，使用者會看到首頁短暫出現再被表單蓋掉的跳動；其二，它把正確性押在時序上，而時序正是這個缺陷的成因——同樣的寫法在動畫較長或裝置較慢時仍可能再次落空。

**該次 stack 設定不帶動畫**。實作期間實測發現，帶動畫的 stack 設定在本專案的 navigation controller 上會產生違反 UIKit 契約的結果：以兩個元素的陣列設定，實際得到三層（`[表單, 首頁, 表單]`）。同一段程式碼改為不帶動畫即穩定得到正確的兩層。未追究 UIKit 內部成因——修正已穩定，且該追究沒有邊界；此處只記錄可重現的觀察。

不帶動畫在這裡另有正當性：deeplink 來自 app 之外（Siri、通知、Spotlight），畫面上沒有需要延續的手勢或視覺脈絡，瞬間切換反而比讓使用者多看 0.35 秒的滑動更直接。

### 導航動作收回 AppRouter，SceneDelegate 不再操作 stack

`SceneDelegate` 改為呼叫新方法，不再自己呼叫 `popToRootViewController`，也不再需要判斷 stack 深度——「先回到根部」成為新方法語意的一部分。

這麼做不只是整潔：`navigation` 要求導航集中於 `AppRouter`、進入點不自帶導航邏輯。原本那行 pop 是唯一的例外，而缺陷正好發生在該例外與中樞之間的接縫。把它收回去，接縫消失。

新方法必須沿用 `to(_:from:)` 既有的轉場樣式標記與 navigation delegate／返回手勢設定，否則以此抵達的畫面其返回行為會與其他畫面不一致。

### 以單元測試守住結果 stack，而非以截圖

`UINavigationController` 在單元測試中可直接建立與操作，因此新方法可以用真正的 navigation controller 驅動，斷言呼叫後的 `viewControllers` 內容。

這比截圖強得多：截圖只能證明「看起來對」，而這個缺陷的表現正是**畫面看起來完全正常**（停在首頁）而目標沒被呈現。斷言 stack 內容才抓得到它。

`SceneDelegate` 本身仍不可測（它需要 scene 與 window），但缺陷位於它呼叫的導航動作內，把該動作移進 `AppRouter` 後即落入可測範圍——這是前一個決策的附帶收穫，也是選它而非「延後一個 runloop turn」的另一個理由：後者測不了。

### 本 change 需排在 remove-tab-bar 之後套用

兩份 delta（`navigation` 的 deeplink requirement、`home-ui` 的設定入口 requirement）都以 `remove-tab-bar` 套用後的內容為基礎改寫。`remove-tab-bar` 把 `home-ui` 那條 scenario 削弱成只宣稱「設定被移出 stack」，正是因為本缺陷讓「表單被推出」不成立；本 change 修好之後把它補回完整。

若先套用本 change，兩份 delta 的 MODIFIED 內容會對不上當時的主 spec。

## Implementation Contract

**行為（使用者可觀察）**

1. 停在首頁時收到食材 deeplink → 抵達該食材的編輯表單（維持現有正確行為）。
2. 正在編輯另一筆食材時收到食材 deeplink → 抵達新食材的編輯表單，stack 不疊層。
3. 停留在設定頁時收到食材 deeplink → 設定被收掉，抵達該食材的編輯表單。
4. 上述三種情形的轉場都是單次動畫，不出現首頁短暫閃現後再被覆蓋。
5. 目標食材已不存在時 → 回到首頁清單、不呈現 detail、不報錯。

   實作期間實測發現此條**原本並不成立**：既有實作在找不到目標時完全不動作，若當時推著編輯表單或設定頁，使用者會留在原地——`navigation` 的 scenario「Following a link to an item that is gone」因此是假的。本 change 一併修正，讓失效的 deeplink 一律回到只剩首頁的狀態。
6. 以此方式抵達的編輯表單，其返回鍵與邊緣返回手勢行為與從首頁點列進入時相同。

**介面／資料形狀**

- `AppRouter` 新增一個方法，語意為「把 stack 設定為『根部 + 目標』並以單次轉場呈現」，簽章形式與既有的 `to(_:from:)` 一致（接受目標 view controller 與來源 view controller），並沿用同一組轉場樣式標記與 navigation delegate／返回手勢設定。
- `AppRouter` 既有的 `to` / `sheet` / `deeplink` / `back` 方法簽章與行為不變。
- `SceneDelegate` 不再出現 `popToRootViewController`，也不再判斷 stack 深度。
- `Deeplink` enum、其 URL 解析與產生完全不變。

**失敗模式**

- 來源 view controller 取不到 navigation controller 時，維持 `AppRouter` 既有的 DEBUG 斷言與靜默返回，不新增崩潰路徑。
- 目標食材不存在時，`showFoodItem` 維持既有的提前返回，不呈現任何畫面。

**驗收標準**

- 新增單元測試，以真正的 `UINavigationController` 驅動新方法，涵蓋三種起始狀態並斷言呼叫後的 `viewControllers`：
  - 起始為 `[root]` → 結果為 `[root, destination]`
  - 起始為 `[root, other]` → 結果為 `[root, destination]`（而非 `[root]`，也非 `[root, other, destination]`）
  - 起始為 `[root, a, b]` → 結果為 `[root, destination]`
- 新增單元測試斷言以新方法抵達的目標帶有與 `to(_:from:)` 相同的轉場樣式標記，確保返回行為一致。
- 模擬器實機驗證三種情形並記錄 stack 內容（非僅截圖）：停在首頁、正在編輯另一筆、停留設定頁。
- 全專案搜尋 `popToRootViewController` 在 `Sources/App/SceneDelegate.swift` 中不再出現。
- 完整測試套件通過且測試數不減少。

**範圍邊界**

- 範圍內：`AppRouter` 新增一個導航方法、`SceneDelegate` 的 `showFoodItem` 改為呼叫它、對應單元測試，以及 `navigation` 與 `home-ui` 兩份 spec 的 delta。
- 範圍外：`Deeplink` 解析、四個進入點的觸發時機、首頁、設定頁、表單、資料層、Widget、通知服務。

## Risks / Trade-offs

- **[單次 stack 設定的轉場外觀可能與 push 略有差異]** → 兩者都經由同一個 navigation delegate 與自訂動畫器，操作型別同為 push。以模擬器實際觀察一次確認，若有差異則調整動畫器而非退回兩次呼叫。
- **[本 change 與 remove-tab-bar 的套用順序有依賴]** → 已在決策中載明；兩份 delta 皆以 remove-tab-bar 套用後的內容為基礎。順序顛倒時 MODIFIED 會對不上，套用會失敗而非靜默錯誤。
- **[單元測試在測試環境建立 UIKit 導航控制器]** → 專案既有測試皆為純 Swift 的 ViewModel 測試，這是第一組碰 UIKit 的測試。實測結果：無 window 時 UIKit 會把**帶動畫**的 stack 變更延後，`viewControllers` 不同步更新，因此測試一律以不帶動畫呼叫。這組測試釘的是契約——不論起始深度，結果恆為「根部 + 目標」；帶動畫時「push 被丟棄」的那一面由記錄真實 stack 內容的模擬器驗證負責。
- **[`appTransitionStyle` 由 fileprivate 放寬為 internal]** → 為了讓「以新方法抵達的畫面其返回行為與 push 一致」測得到。仍限於本模組內、未對外公開；代價小於讓返回行為失去測試覆蓋。
- **[缺陷已存在多個版本，修好後行為改變]** → 這是修正而非行為變更：使用者原本期待的就是抵達目標。沒有任何既有功能依賴「被彈回首頁」。
