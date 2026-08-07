## Context

FoodEntropy 的導航是 push-based：`AppRouter` 從 `source.navigationController` 動態取得堆疊並 push，`back()` 則多半是 pop。這與同一組 mvvmc-* skills 下的 HerbMeet 相反（HerbMeet 因地圖的常駐 sheet 佔用 presentation slot 而改採 present-based）。FoodEntropy 沒有那個限制，所以照 skill 的預設走。

真正的專案特有設計不在「push 或 present」，而在**轉場樣式的記憶方式**：`AppRouter` 把「這個畫面是以什麼方式出現的」寫進目的地 `UIViewController` 的 associated object，讓之後的 `back()` 與手勢判斷都能從畫面自身讀回答案，而不需要呼叫端保存任何狀態。這是 router 得以維持 stateless 的關鍵。

## Goals / Non-Goals

**Goals:**
- 記錄 push-based 的理由（首頁靠 pop 觸發 `onAppear` 重撈）。
- 記錄轉場記憶機制，以及它讓 `back()` 免去呼叫端分支的作用。
- 記錄互動返回手勢只在預設 push 時啟用的理由。
- 記錄 `onRoute` 路由意圖模式的分工界線。
- 記錄集中式 `Deeplink` 與三個進入點的收斂。
- 誠實記錄 v1.0.0 未使用的 API 表面。

**Non-Goals:**
- 無行為變更。
- 不重述 `mvvmc-navigation` skill。
- 不涵蓋 `app-shell` 的 window / tab bar 裝配。

## Decisions

### push-based，而非 HerbMeet 式的 present-based

跨畫面導航一律用 `AppRouter.to()` push 進當前 Tab 自己的 `UINavigationController`。理由：本專案沒有 `@Query`，首頁清單不會自動響應資料變動，刷新機制是「pop 回來時 `onAppear` 重撈」（見 `01-navigation` §3 的生命週期備註）。push/pop 天然提供這個時機；改成 fullScreen modal 則需要額外的 callback 通道才能通知首頁重載。考慮過的替代方案：present-based router（HerbMeet 的做法）——否決，那是為了繞開常駐 sheet 佔用 presentation slot 的問題，FoodEntropy 沒有常駐 sheet，採用它只會平白多一層 callback。

### 轉場樣式記在目的地的 associated object，而不是由呼叫端在 back() 時重述

`AppRouter.to()` 把 `TransitionStyle` 寫進目的地 `UIViewController` 的 `appTransitionStyle`（associated object，預設 `.push`）；`sheet()` 寫入 `.sheet`。`back(from:)` 讀回這個值來決定 dismiss 還是 pop。理由：router 是 stateless 的——不持有 window、nav、也不持有任何「誰從哪裡來」的表格——但 `back()` 仍必須知道當初的進入方式才能選對 UIKit 呼叫。把答案存在畫面自己身上，是唯一不需要 router 保存狀態、也不需要呼叫端記憶的做法。考慮過的替代方案：(a) 讓呼叫端在 `back(style:)` 時再指定一次——否決，等於要求每個 HostController 記住自己是被 push 還是被 sheet 出來的，而它往往不知道（可能有多個進入點）；(b) 由 router 維護一張 VC → style 的對照表——否決，那讓 router 變成有狀態，並引入生命週期與釋放時機問題。

存取 associated object 的 key 宣告為 `nonisolated(unsafe)`，這在 Swift 6 下是安全的：該變數僅作為位址使用，從不被讀寫其內容。

### back() 一律由 router 分流 pop 或 dismiss

`back(from:)` 先讀目的地的 `appTransitionStyle`，`.sheet` 走 `dismiss`，其餘走 `popViewController`；讀不到時退回檢查 `navigationController` 自身的樣式。HostController 一律呼叫 `back`，不自行判斷。理由：把 pop-vs-dismiss 的分支集中在一處，HostController 就不需要知道自己身處哪種呈現方式；否則同一份關閉邏輯要在每個 feature 重寫一次，且容易在新增呈現方式時漏改。

### 互動返回手勢只在預設 push 轉場時啟用

`gestureRecognizerShouldBegin` 只在堆疊深度大於 1、且 `topViewController` 的樣式為 `.push` 時回傳 `true`。理由：自訂的 `UIViewControllerAnimatedTransitioning` 動畫（`.modal` / `.fade`）不是互動式轉場，UIKit 的邊緣滑動 pop 手勢在中途取消時無法正確回捲，會留下錯位或半透明疊層的畫面。限制在系統預設 push 才放行，是最小且不需額外實作互動控制器的做法。iOS 26 新增的 `interactiveContentPopGestureRecognizer` 一併套用同一 delegate，避免新手勢繞過這個判斷。

### ViewModel 發路由意圖，HostController 執行

ViewModel 曝露 `onRoute: (@MainActor (Router) -> Void)?`，`Router` 是該 feature 自己的 enum；HostController 在 `viewDidLoad` 接上，在 private extension 的 `handleRouter` 內把意圖轉成實際的 `AppRouter` 呼叫。ViewModel 不 import UIKit、不持有任何 `UIViewController`。理由：這是 mvvmc-viewmodel / mvvmc-hostcontroller 的既有分工，讓 ViewModel 可以在沒有 UIKit 的情況下被單元測試——測試只需斷言 `onRoute` 收到哪個 case。

### 離開 App 不算導航，不走 AppRouter

開啟系統設定用 `UIApplication.shared.open`，直接寫在 HostController 的 `handleRouter` 內。理由：`AppRouter` 的職責是本 App 內的 view controller 階層操作；離開 App 沒有 source、沒有堆疊、也沒有 back 可言，硬包成 router 方法只會讓 router 的語意變模糊。此處的 `openNotificationSettings` 是唯一這類出口。

### Deeplink 解析集中於單一 enum，三個進入點收斂到同一 handler

`Deeplink(url:)` 是唯一的 URL 解析點：只接受 `foodentropy` scheme，未知 host 回 `nil`。三個進入點——冷啟動 URL、前景 URL、通知點擊——各自取得 URL 後都轉成 `Deeplink` 再交給同一個 `handle(_:)`。通知 payload 的慣例是 `{ "deeplink": "foodentropy://home" }`，缺少 payload 時預設回首頁。理由：三個進入點的觸發時機與執行緒脈絡都不同（冷啟動必須在 `makeKeyAndVisible()` 之後、通知回呼是 `nonisolated`），若各自解析 URL 並各自導航，新增目標時就要改三個地方且容易漏。收斂成「解析 → enum → 單一 handler」後，新增目標只需擴充 enum 與 handler。

## Implementation Contract

**Behavior (observable):**
- 首頁點「＋ 新增食材」或點任一 row，Form 以 push 出現，帶原生返回鈕，且 tab bar 隱藏。
- Form 儲存或取消後回到首頁，首頁清單反映最新資料（pop 觸發重撈）。
- 設定點「隱私權政策」，網頁以可下拉關閉的 page sheet 出現。
- 從 push 進入的畫面可用邊緣滑動返回；從 sheet 進入的畫面不受此手勢影響。
- 點擊到期通知（無論 app 在何種狀態）開啟 app 並停在首頁 Tab。
- 開啟未知的 `foodentropy://` URL 或非本 scheme 的 URL 時，app 不做任何導航。

**Interface / data shape:**
- `AppRouter`：`@MainActor`、`final class`、`static let shared`、private init、stateless（不持有 nav / window / VC）。
- `AppRouter.TransitionStyle`：`.push` / `.modal` / `.fade` / `.sheet`，`Equatable`。
- 主要入口：`to(_:from:style:animated:)`（`style` 預設 `.push`）、`back(from:animated:)`、`sheet(_:from:detents:animated:)`。
- `UIViewController.appTransitionStyle`：fileprivate associated object，預設 `.push`。
- `Deeplink`：`enum`，`init?(url: URL)`，v1 僅 `.home`。
- feature ViewModel：`var onRoute: (@MainActor (Router) -> Void)?`，`Router` 為該 feature 巢狀 enum。

**Acceptance criteria:**
- `grep -rn "navigationController?.pushViewController\|\.present(" Sources/Features` 無結果——所有 UIKit 導航呼叫都只出現在 `AppRouter.swift`。
- 每個 feature ViewModel 皆不 import UIKit：`grep -l "import UIKit" Sources/Features/*/[A-Za-z]*ViewModel.swift` 無結果。
- `AppRouter` 無儲存屬性（除 `shared` 本身）。
- 未知 host 的 `foodentropy://` URL 使 `Deeplink(url:)` 回傳 `nil`。

**Scope boundaries:**
- In scope：`AppRouter` 的 `to` / `back` / `sheet`、轉場記憶、手勢條件、`onRoute` 模式、`Deeplink` 解析與三進入點收斂、離開 App 的界線。
- Out of scope：window 與 tab bar 裝配（`app-shell`）、各畫面內部的操作流程、SwiftData 重撈機制本身（`persistence`）。

## Risks / Trade-offs

- [v1.0.0 只使用了 `AppRouter` 的三個入口] → `backTo`、`backToRoot`、`deeplink`、`tab` 四個方法零呼叫，`.modal` / `.fade` 兩種轉場樣式與整個 `AppTransitionAnimator`（約 80 行）也無任何呼叫端。這些是為未來預留的表面，代價是它們沒有任何使用端驗證過，實際行為未經實機確認。刻意不寫進 spec：規格描述現行契約，不描述未啟用的可能性。是否收斂或啟用，留待未來獨立 change 決定。
- [通知 deeplink 的切 Tab 未經 `AppRouter`] → `SceneDelegate.handle(_:)` 直接設定 `UITabBarController.selectedIndex`，而 `AppRouter.tab(_:from:)` 恰好提供同一功能卻未被使用。這與憲章「不繞過 Router 做導航」存在張力；成因是 deeplink 情境下沒有 source view controller 可傳給 `tab(_:from:)`，而該方法的簽章要求一個。屬已知不一致，非本次 baseline 的修正範圍——修正它需要調整 `AppRouter.tab` 的簽章，是行為變更。
- [轉場樣式存於 associated object] → 這個狀態綁在 `UIViewController` 實例上，無法在單元測試中直接斷言，只能靠實機或 UI 測試驗證 `back()` 的分流是否正確。接受此代價，換得 router 的 stateless 性質。
