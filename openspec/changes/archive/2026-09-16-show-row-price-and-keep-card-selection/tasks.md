## 1. 選取不被搶走

- [x] 1.1 先寫失敗測試 `使用者選過卡之後重載不更動選取`：載入三桶皆有內容的資料、送出點擊某張卡的 ViewAction、再載入一次，斷言選中的仍是那張。另寫 `選中空桶後重載仍維持該桶`：載入只有 fresh 有內容的資料、選中空的過期卡、再載入一次，斷言選中的仍是過期卡。驗證：兩個測試在實作前失敗（現行邏輯會把選取換成最急迫的非空桶）。
- [x] 1.2 依決策「自動挑選分桶只決定初始那一張」在首頁 State 新增一個布林欄位記錄使用者是否已自行選過卡片，預設偽，於點擊卡片的 ViewAction 設為真；載入收尾的自動挑選只在該欄位為偽時執行。交付行為：符合 requirement「Tapping a card brings it forward, and a second tap opens that bucket's list」新增的三個 scenario——首張依緊急度、選過的卡跨重載存活、選中的空桶不被收回。驗證：1.1 兩個測試轉為通過。
- [x] 1.3 新增測試 `未選過卡時載入落在最急迫的非空桶`（涵蓋 scenario「The first card is chosen by urgency」）與 `選中的桶在停留期間變空仍維持選中`。交付行為：初始挑選仍然有效，而「變空」不再等同「換走」。驗證：兩個測試通過；既有 `HomeViewModelTests` 全數仍通過。

## 2. 列上的價格

- [x] 2.1 依決策「價格為列的尾端次要資訊，缺值時整個不渲染」實作 requirement「A food row states its recorded cost, and shows nothing when none was recorded」：食材列在效期色點之前顯示該筆金額，字級低於名稱與到期描述，金額經既有的貨幣格式化入口產生；無記錄價格時不渲染任何金額元素。交付行為：有價格的列看得到金額，沒有的列尾端不出現任何替代符號。驗證：以 `ios-build-run` 在模擬器開啟同時含有價與無價食材的分桶清單，截圖確認兩種列的呈現。
- [x] 2.2 確認列的四個動作未受影響——對應 requirement「A food row states its recorded cost, and shows nothing when none was recorded」的 scenario「The row's actions are unaffected」。交付行為：點擊、左滑、右滑、長按在有金額的列上行為與改動前相同。驗證：模擬器對一筆有價格的食材依序操作四個動作各一次並記錄結果。
- [x] 2.3 確認 widget 未受影響：食材列元件雖被編譯進 widget target（該檔案同時定義效期顏色函式），但 widget 並未渲染它。交付行為：widget 呈現不因本次改動而變。驗證：全專案搜尋確認該元件僅由分桶清單渲染；模擬器截一張 widget 與改動前比對。

## 3. 收尾

- [x] 3.1 建置專案讓編譯器抽取任何新字串，以 `xcrun xcstringstool sync` 把 app 與 widget 兩個 target 的 `.stringsdata` 一併併回 `Sources/Resources/Localizable.xcstrings`，依 repo 既有格式重新輸出以免整檔重排，並補 `zh-Hant` 與逐條處理 stale。交付行為：中英使用者都看到正確文案。驗證：stale 數 = 0、缺翻譯數 = 0，且 `git diff` 不含整檔格式差異。
- [x] 3.2 跑完整測試套件與 `spectra validate show-row-price-and-keep-card-selection`。交付行為：改動完成且規格一致。驗證：測試全數通過且測試數不減少、validate 無錯誤。
