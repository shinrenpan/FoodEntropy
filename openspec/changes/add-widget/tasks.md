## 1. 動工前置：升級實測（gate）

- [ ] 1.1 於 Apple Developer 後台建立 App Group identifier，命名與既有 bundle identifier 慣例一致（design 的待解問題）；驗證：identifier 已存在於後台，且格式為 group 前綴加既有 bundle identifier 的反向網域。
- [ ] 1.2 **gate 判定** — 對應「The store location is never specified explicitly once an app group is adopted」，落實 design 的「不為 App Group 指定容器位置或名稱」：以升級情境實測自動複製。取已有資料的 v1.1.0 build 安裝並建立數筆記錄（含照片與價格），再直接升級為僅加了 App Group entitlement、未修改任何 `ModelConfiguration` 的 build；驗證：升級後所有記錄仍在，照片與價格完整。**iCloud 同步開啟與關閉各測一次。任一未通過即停止本 change，回到 proposal 重新評估資料傳遞方式。**
- [ ] 1.3 記錄實測所觀察到的降級行為 — 對應該 requirement 的「自動複製未發生」情境；驗證：確認複製失敗時 app 是沿用既有記錄繼續運作，而非開出空 store；若觀察到後者，於 proposal 記錄並停止。

## 2. 抽出共用元件（純重構，不得改變視覺）

- [x] 2.1 將首頁「現況」區塊的內容抽至 `Sources/Core/Components/StatusChartView.swift` — 對應「The widget and the in-app screen share one presentation implementation」，落實 design 的「呈現層抽為共用元件，而非在 Widget 重寫一份相似版面」：抽出範圍為甜甜圈、legend 三行、前瞻金額行；元件只接受三個桶的數量與可選金額，不自行讀取資料；`Section` 容器與「現況」標題留在 `Sources/Features/Home/HomeView.swift`；驗證：`HomeView` 不再包含甜甜圈與 legend 的繪製程式碼，且新元件無任何資料讀取。
- [x] 2.2 首頁迴歸驗證；驗證：同一組資料下，抽出前後的首頁「現況」區塊視覺相同；將字級調至最大確認甜甜圈中心數字仍縮放而非截斷；以 VoiceOver 逐項朗讀，內容與抽出前相同（中心唸「N 項」、legend 逐行唸色點對應的桶名與數量、金額行唸完整幣別）。

## 3. Widget extension

- [ ] 3.1 於 `project.yml` 宣告 Widget extension target，並在 app 與 extension 兩者宣告同一個 App Group entitlement — 對應「The widget extension is declared alongside the app in the generated project」；驗證：執行專案產生後，Xcode 專案含該 target，且兩個 target 的 entitlements 皆有該 App Group；不得直接編輯 Xcode 專案檔。
- [ ] 3.2 將 `Sources/Core/Components/StatusChartView.swift` 與其相依的 Domain 型別加入 extension target — 對應「Source files follow the MVVMC folder convention」新增的「A presentation is consumed by both the app and an extension」情境；驗證：extension target 可編譯並引用該元件，且專案中不存在第二份相同實作。
- [ ] 3.3 確認 `SectorMark` 在 WidgetKit 可正確渲染（design 的風險項）；驗證：Widget 預覽中甜甜圈呈現三桶佔比與中心總數；若不可用，改以基本圖形繪出相同版面，共用元件的抽出仍保留。
- [ ] 3.4 實作 extension 端的資料讀取 — 對應「The widget reads data without exposing persisted types」與「The store is reachable by every process that needs it」，落實 design 的「Widget 端的資料讀取自行建立容器，且失敗時不終止」：於 extension 內建立自己的容器（同樣不指定容器位置），讀取後轉為 Domain Model 放入 `TimelineEntry`；驗證：`TimelineEntry` 的屬性只有數量與可選金額，無任何持久化型別；Widget 顯示的數字與 app 首頁一致。
- [ ] 3.5 實作失敗路徑 — 對應「The widget never terminates on failure」：容器建立或讀取失敗時回傳空 entry 並呈現首頁既有的空狀態文案，不使用 `fatalError`；驗證：以無法開啟 store 的情境執行，Widget 顯示空狀態而非空白磚。
- [ ] 3.6 前瞻金額行的版面處理 — 對應「The widget shows the same status figures as the home screen」的無金額情境；驗證：有金額與無金額兩種資料下，Widget 其餘內容位置不變。

## 4. Timeline 策略

- [ ] 4.1 將 timeline 的下一個刷新點設為次日零時 — 對應「The timeline refreshes at each day boundary and on data change」，落實 design 的「Timeline 以每日起始為刷新點，並由 app 在資料變動時主動要求重載」；驗證：將裝置時間推進跨過午夜，Widget 的分桶結果隨日期改變，過程中不開啟 app。
- [ ] 4.2 app 端在新增、標記已使用／丟棄、刪除後要求重新載入 timeline；驗證：於 app 內完成一次標記已使用後返回主畫面，Widget 內容已更新。
- [ ] 4.3 點擊行為 — 對應「Tapping the widget opens the app」；驗證：點擊 Widget 任一處開啟 app 並停在首頁。

## 5. 驗收

- [ ] 5.1 視覺一致性；驗證：同一組資料下，Widget 與首頁「現況」區塊的甜甜圈比例、中心總數、legend 三行數字、前瞻金額四項皆相同。
- [ ] 5.2 空狀態一致性；驗證：清空所有記錄後，Widget 顯示的文案與首頁相同。
- [ ] 5.3 更新 `openspec/specs/README.md` 的 capability map，加入 `widget` 並標註其與 `persistence`、`home-ui`、`food-item` 的關係；驗證：README 可看出 Widget 的資料來自 `persistence`、呈現與 `home-ui` 共用、狀態規則來自 `food-item`。
