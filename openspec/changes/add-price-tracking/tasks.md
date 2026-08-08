## 1. 資料層

- [x] 1.1 於 `FoodItemEntity` 新增 `price: Double?`（optional、無預設值，符合 CloudKit-safe），語意依 design 決策「價格為「這筆記錄的總花費」」，非單價；型別依 design 決策「型別用 `Double` 而非 `Decimal`」 — 實現 `food-item` 的「A food item may carry an optional recorded cost」與 `persistence` 的「The recorded cost is persisted as an optional attribute and survives resolution」；驗證：未帶價格建立的食材可正常存取且 `price` 為 nil。
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

## 4. 在地化與格式化修正（實作過程發現的既有漏洞）

- [x] 4.0a 抽出共用的金額格式化入口，移除硬編貨幣 fallback；驗證：`grep -rn '"USD"|currency?.identifier' Sources` 僅命中 `CurrencyFormat.swift`；`CurrencyFormatTests` 驗證取不到貨幣資訊時退為純數字而非假裝為某幣別。
- [x] 4.0b 浪費率改用 `.percent` FormatStyle，不再手動接百分比符號 — 實現 `localization` 的「Percentages are formatted by the system, like currency and dates」；驗證：HomeView 內無「數字後直接接百分比符號」的字串插值。
- [x] 4.0c legend 的桶名改為字面值直接寫在 `Text()` 內 — 實現 `localization` 的「Localised literals must appear directly inside the presenting call」；驗證：`grep -rn "LocalizedStringKey(" Sources` 無結果；Xcode build 後三個桶名不再被標為 stale。
- [x] 4.0d 修正翻譯掛在未選用變體上的既有 bug，並清理 String Catalog；驗證：catalog 的 stale 數為 0、缺英文翻譯數為 0（100 → 79 條）。

## 5. 外部作業與驗收

- [x] 5.1 重新部署 CloudKit Production schema（additive）— 實現 `persistence` 的「Every attribute must be written at least once before deploying the schema」：部署前先讓每個欄位實際被寫入一次，再核對 development 的欄位清單；驗證：CloudKit Console 的 Production 環境顯示 `CD_price` 已存在。**部署時另發現 resolvedAt 欄位自 v1.0.0 起從未進入 production schema，已一併修復**——見 `persistence` 新增的部署前驗證要求。
- [x] 5.2 iCloud 同步跨裝置驗證：於 A 裝置填價格，B 裝置同步後金額一致；驗證：**已於 iPhone + iPad 完成**——兩台皆安裝 Debug 版（同為 CloudKit development 環境）、登入同一 Apple ID 並開啟同步；iPhone 新增帶價格食材後，iPad 同步取得該筆且即將到期金額顯示相同數字。iPad 需切換 Tab 觸發重撈才更新，符合 `persistence` 的明確重撈設計。
- [x] 5.3 既有使用者升級驗證：以舊版建立資料後安裝新版——對應「Adding the attribute does not disturb existing records」；驗證：**已於真機完成**——刪除後裝回 App Store 正式版（v1.0.0 build 2，舊 schema）建立 2 筆資料，再以 Xcode 覆蓋安裝新版：2 筆資料完整保留、前瞻金額整行不渲染（既有資料 price 為 nil）、編輯頁價格欄位為空、Xcode log 無任何 SwiftData／CoreData／CloudKit 錯誤（僅 AdMob 與系統雜訊）。
- [x] 5.4 無障礙檢查：價格欄位與金額文字支援 Dynamic Type 且有 VoiceOver 標籤；驗證：**已於真機完成**——最大輔助使用字級下版面不破（環形圖中心加上縮放以免撐出固定尺寸的圓圈）；VoiceOver 唸出的是完整語意。過程中修正六處**既有**缺陷（皆非本 change 引入）：
  - 金額被唸成「99 美金」——TWD 視覺顯示為 `$`，VoiceOver 依符號誤判幣別。改以 `accessibilityLabel` 提供 `.presentation(.fullName)` 版本（「99元」），視覺維持符號形式。
  - 環形圖逐一唸出資料點（「1, 3, 1」）——資訊已由 legend 提供，改為對 VoiceOver 隱藏；中心總數不在 legend 內故保留，並以明確 label 唸作「N 項」（`.combine` 會插入停頓唸成「N、項」）。
  - 浪費長條圖唸出「聲波圖／y 軸為 resolved」等內部細節——Chart 自帶 accessibility tree 與聲波圖，外層覆寫 label 無效，改為隱藏；其資訊已由下方「吃掉 N／丟棄 N」提供。
  - 前瞻金額的驚嘆號 icon 被唸成「錯誤影像」、`FoodRowView` 無照片時的佔位圖示同類問題——皆為純裝飾，加 `accessibilityHidden`。
  - legend 三行分開朗讀經確認為**正確行為**，未更動：逐項瀏覽是 VoiceOver 的核心互動，合併反而無法跳過或單獨重聽。
  - 六處修正未新增任何使用者可見字串（`accessibilityLabel` 皆複用既有句子），Xcode build 後 catalog 零變動。
