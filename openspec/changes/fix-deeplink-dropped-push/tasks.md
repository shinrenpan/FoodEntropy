## 1. AppRouter 的原子導航方法

- [x] 1.1 依決策「以單元測試守住結果 stack，而非以截圖」先寫失敗測試 `取代整個 stack 後只剩根部與目標`：以真正的 `UINavigationController` 建立三種起始狀態（`[root]`、`[root, other]`、`[root, a, b]`），對每種呼叫新方法後斷言 `viewControllers` 皆為 `[root, destination]`。驗證：三個斷言在方法不存在時編譯失敗。
- [x] 1.2 依決策「以單次原子的 stack 設定取代「pop 後再 push」」在 `AppRouter` 新增該方法：把 stack 一次設定為「根部 + 目標」並以單次轉場呈現，不做兩次導航呼叫。交付行為：不論起始深度，結果 stack 恆為根部加目標，且 UIKit 只看到一次轉場。驗證：1.1 的三個斷言轉為通過。
- [x] 1.3 讓新方法沿用 `to(_:from:)` 既有的轉場樣式標記與 navigation delegate／返回手勢設定——對應 requirement「A single food item is a deeplink destination」中「抵達不得依賴當時畫面」的要求，以及 design 決策「導航動作收回 AppRouter，SceneDelegate 不再操作 stack」。交付行為：以此抵達的畫面，返回鍵與邊緣返回手勢行為與從首頁 push 進入時相同。驗證：新增測試 `取代 stack 的目標帶有與 push 相同的轉場樣式`，斷言目標的轉場樣式標記與經 `to(_:from:)` 抵達者相同。

## 2. SceneDelegate 改用新方法

- [x] 2.1 `showFoodItem` 改為呼叫 1.2 的新方法，移除其中的 `popToRootViewController` 與 stack 深度判斷——「先回到根部」成為新方法語意的一部分。交付行為：`SceneDelegate` 不再自行操作 navigation stack。驗證：搜尋 `Sources/App/SceneDelegate.swift` 不再出現 `popToRootViewController`；專案建置通過。
- [x] 2.2 查核「目標食材已不存在」的既有行為是否符合 requirement「A single food item is a deeplink destination」。**查核結果：不符合**——既有實作在找不到目標時完全不動作，若當時推著任何畫面，使用者會留在原地，而 scenario 要求回到首頁清單。交付行為：查核有結論並記錄於 design 的 Implementation Contract 第 5 點。驗證：模擬器以不存在的 UUID 在「已推著一層」的狀態下觸發，記錄到的 stack 未回到首頁，據此開出 2.3。

- [x] 2.3 讓「目標食材已不存在」時回到首頁清單，而非停在收到 deeplink 當下的畫面——對應 requirement「A single food item is a deeplink destination」的 scenario「Following a link to an item that is gone」。實機驗證發現既有實作在此情形下完全不動作：若當時推著編輯表單或設定頁，使用者會留在原地，該 scenario 並不成立。交付行為：失效的 deeplink 一律讓 stack 回到只剩首頁，且不報錯。驗證：模擬器以不存在的 UUID 在「已推著一層」的狀態下觸發，記錄 stack 僅含首頁。

## 3. 實機驗證

- [x] 3.1 以模擬器驗證 requirement「A single food item is a deeplink destination」新增的 scenario「Following an item link from any other screen」與既有的「Following two item links in succession」：分別在停留首頁、正在編輯另一筆食材、停留設定頁三種狀態下觸發食材 deeplink，每次記錄 navigation stack 內容。交付行為：三種狀態的結果 stack 皆為「首頁 + 目標食材的編輯表單」。驗證：三筆 stack 記錄皆符合，特別確認第二、三種不再停在只剩首頁的狀態。（`simctl openurl` 會被系統確認框擋住且無法自動點擊，故以 DEBUG 環境變數直接呼叫真正的 `handle(_:)`，驗畢移除。）
- [x] 3.2 依 requirement「Settings is reached from the home screen's navigation bar」中 deeplink 抵達設定頁時的 scenario，確認抵達是單次、原子的——不出現「先回到首頁、再彈出表單」的兩段跳動。依 design，該次 stack 設定不帶動畫（帶動畫會產生違反 UIKit 契約的三層結果），故表現為瞬間切換。交付行為：符合 design 的「抵達動作是原子的」。驗證：截圖確認最終停在目標食材的編輯表單，且 stack 記錄為首頁加表單兩層。

## 4. 收尾

- [x] 4.1 跑完整測試套件與 `spectra validate fix-deeplink-dropped-push`。交付行為：改動完成且規格一致。驗證：測試全數通過且測試數不減少、validate 無錯誤。
- [x] 4.2 確認本 change 的兩份 delta 以 `remove-tab-bar` 套用後的主 spec 為基礎——依 design 決策「本 change 需排在 remove-tab-bar 之後套用」，若 `remove-tab-bar` 尚未 archive 則先完成它。交付行為：archive 時兩份 MODIFIED 能正確對上主 spec。驗證：archive 前確認 `openspec/changes/remove-tab-bar/` 已不在作用中變更清單裡。
