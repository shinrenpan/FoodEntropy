## 1. 資料層

- [x] 1.1 於 `FoodItemEntity` 新增 `price: Double?`（optional、無預設值，符合 CloudKit-safe），語意依 design 決策「價格為「這筆記錄的總花費」」，非單價 — 實現 `food-item` 的「A food item may carry an optional recorded cost」與 `persistence` 的「The recorded cost is persisted as an optional attribute and survives resolution」；驗證：未帶價格建立的食材可正常存取且 `price` 為 nil。
- [x] 1.2 於 Domain `FoodItem` 新增 `price: Double?` 並更新 `toDomain()` — 實現「A food item may carry an optional recorded cost」；驗證：`toDomain()` 帶出的 `price` 與 entity 一致（含 nil 情形）。
- [x] 1.3 `SwiftDataManager.create(...)` 與 `update(...)` 新增 `price: Double?` 參數；驗證：新增測試——建立帶價格的食材後重新 fetch，`price` 相符；`update` 可將既有 nil 改為有值、亦可改回 nil。
- [x] 1.4 確認 `resolve(id:to:)` **未觸及** `price`——對應 design 決策「解析食材時清除圖片，但**保留**價格」，實現「The recorded cost is persisted as an optional attribute and survives resolution」；驗證：新增測試——對帶價格的食材呼叫 `markWasted`，重新 fetch 後 `price` 仍存在而 `imageData` 為 nil。**此為本 change 最易出錯處**：實作時若照抄相鄰的 `imageData = nil` 一併清除，回顧金額會靜默失效。
- [x] 1.5 更新 `FoodItemMocks` 使部分 mock 帶價格；驗證：`SEED_MOCKS=1` 啟動後首頁出現即將到期金額。

## 2. Form 輸入

- [x] 2.1 `FoodFormViewModel.State` 新增價格欄位，納入 `Snapshot` 但不納入 `isSaveEnabled` — 實現 `food-form-ui` 的「The form accepts an optional cost alongside the purchase date」；驗證：名稱有效而價格留空時儲存鈕啟用；僅改價格後返回會跳放棄確認。
- [x] 2.2 於 `FoodFormView` 購買日期所在 Section 加入價格欄位，使用 `.decimalPad` 並允許小數，不附加說明文字（App 主打簡單）— 實現「The form accepts an optional cost alongside the purchase date」；驗證：實機點擊該欄位跳出數字鍵盤且可輸入小數點。
- [x] 2.3 價格顯示交由系統依 locale 格式化，欄位本身只收數值、不含貨幣符號——對應 design 決策「輸入不帶符號，顯示交由系統格式化」；驗證：`grep -rn "NumberFormatter\|currencyCode" Sources` 無結果；切換裝置地區後顯示的貨幣格式隨之改變。
- [x] 2.4 `save()` 將價格一併寫入；驗證：填價格儲存後，重新進入編輯頁該值仍在；對 active 食材補填價格後返回首頁，即將到期金額隨即增加。

## 3. 首頁呈現

- [x] 3.1 `HomeViewModel.State` 新增前瞻金額（`nearExpiry` 桶中 `price` 非 nil 者的總和）——對應 design 決策「前瞻金額只取 `nearExpiry` 桶，不含 `expired` 與 `fresh`」，實現 `home-ui` 的「The amount about to expire is surfaced while the food can still be saved」；驗證：新增 `HomeViewModelTests` 案例——注入含 fresh／nearExpiry／expired 三類且部分帶價格的資料，斷言僅 `nearExpiry` 且有價格者被計入。
- [x] 3.2 `HomeViewModel.State` 新增已丟棄金額（統計視窗內 `wasted` 且 `price` 非 nil 者的總和）— 實現 `home-ui` 的「Discarded cost appears as secondary information in waste statistics」；驗證：測試斷言視窗外的已丟棄項目不計入，與既有百分比的視窗一致。
- [x] 3.3 於首頁顯示前瞻金額，文案固定為「至少」語氣——對應 design 決策「一律以「至少」語氣呈現，而非條件式」，實現「The amount about to expire is surfaced while the food can still be saved」；驗證：文案字串走 String Catalog；涵蓋率不同時文案不變。
- [x] 3.4 前瞻金額在無可計算資料時整行不渲染——對應 design 決策「沒有可計算的金額時整行不渲染，而非顯示零或引導」，實現 `home-ui` 的「The upcoming amount disappears rather than reporting zero」；驗證：清空所有價格後該行消失，且畫面不出現 0 或引導文案。
- [x] 3.5 於浪費統計區加入已丟棄金額作為附屬資訊，百分比維持主要位置 — 實現「Discarded cost appears as secondary information in waste statistics」；驗證：實機檢視該區，金額的視覺層級低於浪費率。

## 4. 外部作業與驗收

- [ ] 4.1 重新部署 CloudKit Production schema（additive）；驗證：CloudKit Console 顯示 `price` 欄位已存在於 Production 環境。
- [ ] 4.2 iCloud 同步跨裝置驗證：於 A 裝置填價格，B 裝置同步後金額一致；驗證：兩裝置的即將到期金額相同。
- [ ] 4.3 既有使用者升級驗證：以舊版建立資料後安裝新版——對應「Adding the attribute does not disturb existing records」；驗證：既有食材正常載入、`price` 為 nil、無資料遺失、前瞻金額不顯示。
- [ ] 4.4 無障礙檢查：價格欄位與金額文字支援 Dynamic Type 且有 VoiceOver 標籤；驗證：放大字級不破版，VoiceOver 讀出的是完整語意而非裸數字。
