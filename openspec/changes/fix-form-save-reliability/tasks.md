## 1. State 與 Action 骨架

- [x] 1.1 依決策「儲存進行中以 State 欄位表達，並同時關閉儲存鈕」，在 `FoodFormViewModel.State` 加入儲存進行中與失敗警示兩個布林欄位，兩者預設 false，`State` 仍滿足 `Equatable, Sendable`。交付行為：ViewModel 能以狀態表達「正在儲存」與「上一次儲存失敗」。驗證：`swift build` 等價的專案建置通過，且既有 `FoodFormViewModelTests` 全數仍通過（新欄位不得改變任何既有斷言）。
- [x] 1.2 依決策「寫入失敗以 DataResponse action 回流，使失敗路徑可測」，在 `FoodFormViewModel` 加入 `dataResponse` action 與含「儲存成功／儲存失敗」兩種 case 的 response enum，並在 `doAction` 分派到對應處理；`Action` 與新 enum 維持 `Sendable`。交付行為：失敗路徑可由外部以一個 action 直接驅動，不需 mock。驗證：新增測試 `儲存失敗 response 使表單留在畫面`，直接送出失敗 response 並斷言 `onRoute` 未被呼叫。
- [x] 1.3 確認「未儲存變更」比對用的 snapshot 結構**不**納入 1.1 新增的兩個 UI 狀態欄位。交付行為：顯示過儲存失敗警示後，返回時不會被誤判為有未儲存變更。驗證：新增測試 `失敗警示不算未儲存變更`——初始狀態下送入儲存失敗 response，再送返回動作，斷言未跳出放棄確認。

## 2. 防重送

- [x] 2.1 先寫失敗測試 `儲存進行中再次觸發不寫入`：把 ViewModel 置於儲存進行中狀態後送出儲存動作，斷言 manager 沒有新增任何紀錄；另寫 `儲存結束後清除進行中狀態` 斷言一次正常儲存後進行中狀態為 false。驗證：兩個測試在實作前失敗。（不採「連送兩次儲存動作」的寫法——測試注入的 no-op NotificationService 完全同步，兩次呼叫不會重疊，該寫法驗證不到 guard。）
- [x] 2.2 實作 requirement「Saving writes, then requests permission, then reconciles reminders, then closes」中新增的進行中規則——儲存動作進入時若已在進行中則直接返回，否則標記進行中，結束（成功或失敗）時清除。交付行為：一次儲存只會產生一筆紀錄、一次權限請求、一次排程重建。驗證：2.1 的測試轉為通過，且既有的 `add 儲存後 manager 新增一筆`、`edit 儲存後 manager 更新既有筆` 仍通過。
- [x] 2.3 讓 `FoodFormView` 的儲存鈕在名稱為空**或**儲存進行中時失效，`isSaveEnabled` 本身的定義維持不變（仍只看名稱，對應 requirement「Saving requires a name that is not blank」）。交付行為：儲存期間使用者看得出儲存鈕不可用。驗證：新增測試 `儲存鈕可用條件` 涵蓋三種組合（名稱空→不可用、名稱有值且未在儲存→可用、名稱有值但儲存中→不可用）；既有測試 `名稱去空白後為空則不可儲存` 仍通過；確認 View 的 `.disabled` 綁的是新的組合條件而非 `isSaveEnabled`。（不採「模擬器肉眼確認」——該狀態只存在數十毫秒，截圖抓不到，寫成驗收條件等於寫一條做不到的驗收。）

## 3. 失敗路徑

- [x] 3.1 先寫失敗測試 `儲存失敗時不關閉表單且顯示警示`：送入儲存失敗 response，斷言 `onRoute` 未被呼叫、失敗警示狀態為 true、儲存進行中狀態已清除。驗證：該測試在實作前失敗。
- [x] 3.2 依決策「寫入失敗時停在表單，且不執行後續兩步」，把儲存改為捕捉資料層丟出的錯誤：失敗時送出失敗 response 並就地返回，不請求通知權限、不重建排程、不關閉表單；成功時維持既有順序（寫入 → 請求權限 → 重建排程）後送出成功 response 才關閉。交付行為：符合 requirement「Saving writes, then requests permission, then reconciles reminders, then closes」的失敗分支。驗證：3.1 轉為通過；新增測試 `儲存成功 response 關閉表單` 斷言成功 response 會觸發 `onRoute(.close)`。
- [x] 3.3 在 `FoodFormView` 加入儲存失敗的 alert，綁定 1.1 的失敗警示欄位，只提供一個確認鈕；關閉後表單可直接再次儲存。字面值以英文直接寫在 `alert` 與 `Button` 內，不得以變數傳遞 `LocalizedStringKey`。交付行為：使用者在寫入失敗時會看到明確訊息且輸入原樣保留。驗證：以 `ios-build-run` 建置通過；因真實寫入失敗無法按需重現，行為正確性由 3.1／3.2 的測試涵蓋，此處只驗證 alert 能正常編譯與呈現（暫時把失敗欄位預設為 true 在模擬器目視一次後改回）。

## 4. 在地化

- [x] 4.1 建置專案讓編譯器抽取 3.3 的新字串，再以 `xcrun xcstringstool sync` 把產生的 `.stringsdata` 併回 `Sources/Resources/Localizable.xcstrings`。交付行為：新字串以編譯器產生的 key 進入 String Catalog。驗證：`git diff` 顯示 catalog 新增對應條目。
- [x] 4.2 為 4.1 產生的新 key 補上 `zh-Hant` 翻譯，並逐條處理任何 stale 條目（動態 key 誤判 → 改回字面值；翻譯掛在未選用變體 → 搬到活的 key；功能已移除 → 刪）。交付行為：中英使用者都看得到正確的儲存失敗訊息。驗證：stale 數 = 0 且缺翻譯數 = 0。

## 5. 規格對齊與收尾

- [x] 5.1 確認決策「首頁列操作維持靜默」確實落實——`HomeViewModel` 的五個寫入路徑不在本次改動範圍內，維持現狀。交付行為：本 change 沒有把範圍外溢到首頁。驗證：`git diff --stat` 不含 `Sources/Features/Home/` 下任何檔案。
- [x] 5.2 確認決策「persistence 的免責條件收斂為「失敗後畫面不變」」與 requirement「Read failures yield empty results and write failures reach the caller」的 delta 描述與實際實作一致：表單不再忽略失敗、首頁仍忽略、助理路徑仍回報錯誤。驗證：對照 delta spec 的判準表逐列核對程式碼實際行為。
- [x] 5.3 跑完整測試套件與 `spectra validate fix-form-save-reliability`。交付行為：改動完成且規格一致。驗證：測試全數通過（既有 106 項不得有任何退化）、validate 無錯誤。
