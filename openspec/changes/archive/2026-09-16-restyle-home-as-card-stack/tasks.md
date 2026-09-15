## 1. 首頁的卡片身分與選取

- [x] 1.1 先寫失敗測試 `點未選中的卡只改變選中身分`：送出點擊某張未選中卡片的 ViewAction，斷言選中身分改變且未發出前往清單的導航意圖。另寫 `點已選中的非空分桶卡才發出前往清單的意圖`、`點已選中的摘要卡不發出`、`點已選中但為空的分桶卡不發出`。驗證：四個測試在型別不存在時編譯失敗。
- [x] 1.2 依決策「五張卡一疊，選中者排在最後完整顯示」新增表示首頁卡片身分的列舉（五個成員，分桶成員可取得對應的 `ExpiryStatus`、摘要成員為 nil），並在首頁 State 加入選中身分與待呈現分桶兩個欄位，State 維持 `Equatable, Sendable`。交付行為：首頁能以狀態表達「哪張卡在前面」與「要不要呈現清單」。驗證：1.1 的四個測試可編譯。
- [x] 1.3 依決策「點一下移到前面，再點一次才開清單」實作 requirement「Tapping a card brings it forward, and a second tap opens that bucket's list」：點擊只改變選中身分；僅當該卡原本已選中、是分桶卡、且該桶非空時才發出前往清單的導航意圖。交付行為：使用者可連續瀏覽卡片而不被呈現任何 modal。驗證：1.1 的四個測試全部轉為通過。
- [x] 1.4 新增測試 `清單關閉後待呈現分桶回到 nil` 並實作對應的 ViewAction。另確認既有行為「選中的分桶變空時自動移到最急迫的非空分桶」仍成立，對應 requirement「Items are grouped into three expiry buckets, most urgent first, and empty buckets still appear」。驗證：新測試通過，既有 `HomeViewModelTests` 全數仍通過。

## 2. BucketList feature

- [x] 2.1 先寫失敗測試 `點列發出編輯意圖`、`關閉發出關閉意圖`：對 `BucketListViewModel` 設定 `onRoute` 收集器，分別送出點列與關閉的 ViewAction，斷言收到對應的 Router case。驗證：兩個測試在型別不存在時編譯失敗。
- [x] 2.2 依決策「分桶清單是獨立的 MVVMC feature，以 UIKit 導覽控制器呈現於 sheet」建立 `BucketListViewModel` 與其 State：持有該桶的食材、以 `doAction` 單一進入點處理列的四個動作與關閉，導航意圖以 `onRoute` 發出。交付行為：清單的行為可在不碰 UIKit 的情況下被測試。驗證：2.1 兩個測試轉為通過。
- [x] 2.3 建立 `BucketListView`：內容為 `List`，每列沿用既有的食材列元件與其四個手勢——對應 requirement「Each row offers four distinct actions across separate gestures」。清單尾端附上手勢說明，對應 requirement「A hint describes the gestures that are not otherwise discoverable」。交付行為：四個動作與改動前完全相同，且不需自行實作任何手勢。驗證：以 `ios-build-run` 在模擬器逐一操作四個動作各一次並記錄結果。
- [x] 2.4 建立 `BucketListHostController`，處理 ViewModel 的導航意圖：編輯意圖以 `AppRouter` 的預設 push 推入食材表單、關閉意圖收起自身。交付行為：符合 requirement「Default navigation is a push onto the stack the caller belongs to」——推入落在 sheet 自己的堆疊上。驗證：專案建置通過；實際行為於 4.2 驗證。
- [x] 2.5 依 requirement「On-screen food items are annotated for assistant resolution」把螢幕感知標註掛在 `BucketListView` 的食材列上，並確認首頁的卡片**不帶**任何標註。交付行為：助理解析「這個」的對象隨食材列移到清單畫面。驗證：全專案搜尋該標註僅出現於清單的列，未出現於首頁版面檔。

- [x] 2.6 把列相關的動作與狀態從首頁 ViewModel 遷移到 `BucketListViewModel`：點列、標記已使用、標記丟棄、刪除（含確認）、延長效期。首頁不再有食材列，留著即為死碼。既有測試中驗證這些行為者一併遷移到 `BucketListViewModelTests`，不得刪除任何一條斷言。交付行為：列動作的行為完全不變，只是換了持有者。驗證：遷移後測試總數不減少；首頁 ViewModel 搜尋不到那些 case。

## 3. 首頁版面

- [x] 3.1 依決策「首頁不再使用 List，改為捲動容器」把首頁主體改為捲動容器加垂直堆疊，實作 requirement「The home screen is a stack of cards and the working list sits behind one of them」：廣告位仍釘在上方、新增按鈕仍釘在下方，五張卡構成單一堆疊，首頁不再渲染任何食材列。交付行為：五張卡同時可見，各自至少露出名稱與主要數字。驗證：模擬器截圖確認五張卡皆可見且首頁無食材列。
- [x] 3.2 依決策「五張卡一疊，選中者排在最後完整顯示」實作卡片排列：未選中者依緊急度排列並被下一張壓住只露頂緣，選中者置於最後完整顯示。交付行為：任何一張卡被選中時都不被遮擋。驗證：分別讓摘要卡與分桶卡在前景，各截一張圖確認前景卡完整、其餘露頂。
- [x] 3.3 依決策「摘要卡的內容置於淺色面板內，分桶卡的內容直接畫在卡面上」實作兩類卡片的內容呈現，並調整 `StatusChartView` 在卡片內不再呈現為兩塊各自獨立的區塊。交付行為：環形圖與浪費統計在有色卡面上維持可讀。驗證：模擬器截圖確認摘要卡內容可讀；另截 Widget 一張與改動前比對，確認 Widget 呈現未變。
- [x] 3.4 依決策「卡面內容是金額與時間兩個事實，沒有金額時時間升為主要資訊」實作 requirement「A bucket card states an amount, or the soonest expiry when no amount is recorded」：有金額時金額為主、最近一筆到期時間為輔；無金額時只顯示到期時間；空桶顯示無項目。時間取該桶第一筆，沿用食材列既有的到期字串不新增翻譯。交付行為：任何情況都不出現零金額或鼓勵記錄價格的提示。驗證：分別以「該桶有金額」與「該桶無金額」兩種資料各截一張圖。
- [x] 3.5 依決策「分桶卡的內容區高度固定」讓三張分桶卡在前景時高度一致。交付行為：在分桶之間切換時整疊不跳動。驗證：量測兩種分桶（有金額／無金額）在前景時的整疊高度，兩者必須相同。
- [x] 3.6 依 requirement「Tapping a card brings it forward, and a second tap opens that bucket's list」在已選中且非空的分桶卡上加入可見的開啟指示符號，摘要卡與空桶不顯示。交付行為：第二次點擊不是隱藏互動。驗證：截圖確認前景分桶卡有該符號、摘要卡沒有。

## 4. 呈現與導航

- [x] 4.1 首頁 HostController 處理「呈現分桶清單」的導航意圖：建立 `BucketListHostController`、包在 `UINavigationController` 內，以 `AppRouter` 既有的 sheet 方法呈現；清單關閉時回送 ViewAction 讓首頁清除待呈現分桶。交付行為：點第二次會開啟該桶的清單。驗證：模擬器實際操作一次並截圖。
- [x] 4.2 以模擬器驗證 requirement「Default navigation is a push onto the stack the caller belongs to」新增的 scenario「Editing from within a presented list returns to that list」：在清單中點食材開啟編輯表單，**離開表單後**確認回到清單而非首頁。交付行為：推入落在 sheet 自己的堆疊，且返回是 pop 而非收掉整個 sheet。驗證：分別記錄「推入後」與「離開後」的 sheet stack，後者必須只剩清單且 sheet 仍在呈現中。（只驗推入不足以涵蓋此 scenario——離開才是它敘述的行為。）
- [x] 4.2b 修正 `AppRouter` 的返回行為：來源以 push 抵達且堆疊深度大於一時先 pop，只有在堆疊根部才考慮收起整個呈現式堆疊。交付行為：sheet 內的表單返回時退回清單，sheet 不關閉。驗證：新增測試 `在呈現式堆疊內返回是 pop 而非收掉整個堆疊` 與 `呈現式堆疊的根畫面返回仍是收掉整個堆疊` 皆通過。
- [x] 4.3 依 requirement「The screen reloads on appearing and reconciles reminders after data changes」驗證資料同步：在清單中標記一筆已使用，確認清單即時更新；關閉清單後確認首頁卡片的數量與金額同步。交付行為：清單內的動作不需重開即反映，首頁關閉後反映。驗證：兩個時點各截一張圖，數字與動作前不同。

- [x] 4.4 依 requirement「Deeplink parsing is centralised in one enum」與「A single food item is a deeplink destination」的新措辭，確認兩者不再以「home list」描述首頁——首頁已不是清單。另更新沒有 delta 機制的敘述：`home-ui` 與 `advertising` 的 Purpose、以及 `openspec/specs/README.md` 的 capability map。交付行為：規格全份對首頁的描述與卡片堆疊一致。驗證：主 spec 套用後，以 `home list` 與「分桶清單」搜尋 `openspec/specs/` 無過時命中。

## 5. 在地化與收尾

- [x] 5.1 修正底部新增按鈕下緣間距的註解：數值維持現值，但原註解所述理由（與 tab bar 拉開距離）在 tab bar 移除後已不存在。交付行為：註解與實際理由一致。驗證：搜尋該檔案不再出現 tab bar 字樣。
- [x] 5.2 建置專案讓編譯器抽取新字串，以 `xcrun xcstringstool sync` 把 app 與 widget 兩個 target 的 `.stringsdata` 一併併回 `Sources/Resources/Localizable.xcstrings`，依 repo 既有格式重新輸出以免整檔重排，並補上 `zh-Hant` 翻譯與逐條處理 stale。交付行為：中英使用者都看到正確文案。驗證：stale 數 = 0、缺翻譯數 = 0，且 `git diff` 不含整檔格式差異。
- [x] 5.3 跑完整測試套件與 `spectra validate restyle-home-as-card-stack`，並確認 requirement「The home screen carries both the current overview and the working list」與「Default navigation is a push onto the single navigation stack」兩條舊敘述已由各自的替代 requirement 取代。交付行為：改動完成且規格一致。驗證：測試全數通過且測試數不減少、validate 無錯誤、主 spec 套用後搜尋不到那兩條舊 requirement 名稱。
