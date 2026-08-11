## 1. 動工前置：升級實測（gate）

- [x] 1.1 於 Apple Developer 後台建立 App Group identifier，命名與既有 bundle identifier 慣例一致（design 的待解問題）；驗證：identifier 已存在於後台，且格式為 group 前綴加既有 bundle identifier 的反向網域。
- [x] 1.2 **gate 判定** — 對應「The store location is never specified explicitly once an app group is adopted」，落實 design 的「不為 App Group 指定容器位置或名稱」：以升級情境實測自動複製。取已有資料的 v1.1.0 build 安裝並建立數筆記錄（含照片與價格），再直接升級為僅加了 App Group entitlement、未修改任何 `ModelConfiguration` 的 build；驗證：**已完成，兩輪皆通過**——(a) iCloud 關閉（模擬器）：升級後 10 筆記錄完整，`_EXTERNAL_DATA` 的圖片一併搬入 App Group 容器；刪除 app 私有容器的 store 後資料仍在，證明 app 讀的確實是新位置。(b) iCloud 開啟（實機）：升級前 3 項／$500，升級後 3 項與照片完整。**關鍵佐證**：SDK 介面確認 `ModelConfiguration` 的 `groupContainer` 預設值即為 `.automatic`，故「只加 entitlement、不碰 `ModelConfiguration`」成立，`SwiftDataManager` 全程零修改。
- [x] 1.3 記錄實測所觀察到的降級行為 — 對應該 requirement 的「自動複製未發生」情境；驗證：**已完成，未觸發降級**——`makeResilient` 第一層即成功，無需退回本機或記憶體。兩項附帶觀察值得記錄：(a) **SwiftData 是複製而非移動**，舊位置的 `default.store` 仍留存，實際影響是資料庫佔用雙倍空間（含外部圖片），公開文件未說明何時清除。(b) **iCloud 開啟時 CloudKit 會出現一次 `Change Token Expired`（21/2026）**，訊息為 client knowledge differs from server knowledge，系統隨即以 `ServerChangeTokenExpired` 為由自動 reset 並重新同步，資料未受影響——此即 design 待解問題「與 CloudKit 併用時的行為」的答案。

## 2. 抽出共用元件（純重構，不得改變視覺）

- [x] 2.1 將首頁「現況」區塊的內容抽至 `Sources/Core/Components/StatusChartView.swift` — 對應「The widget and the in-app screen share one presentation implementation」，落實 design 的「呈現層抽為共用元件，而非在 Widget 重寫一份相似版面」：抽出範圍為甜甜圈、legend 三行、前瞻金額行；元件只接受三個桶的數量與可選金額，不自行讀取資料；`Section` 容器與「現況」標題留在 `Sources/Features/Home/HomeView.swift`；驗證：`HomeView` 不再包含甜甜圈與 legend 的繪製程式碼，且新元件無任何資料讀取。
- [x] 2.2 首頁迴歸驗證；驗證：同一組資料下，抽出前後的首頁「現況」區塊視覺相同；將字級調至最大確認甜甜圈中心數字仍縮放而非截斷；以 VoiceOver 逐項朗讀，內容與抽出前相同（中心唸「N 項」、legend 逐行唸色點對應的桶名與數量、金額行唸完整幣別）。

## 3. Widget extension

- [x] 3.1 於 `project.yml` 宣告 Widget extension target，並在 app 與 extension 兩者宣告同一個 App Group entitlement — 對應「The widget extension is declared alongside the app in the generated project」；驗證：執行專案產生後，Xcode 專案含該 target，且兩個 target 的 entitlements 皆有該 App Group；不得直接編輯 Xcode 專案檔。
- [x] 3.2 將 `Sources/Core/Components/StatusChartView.swift` 與其相依的 Domain 型別加入 extension target — 對應「Source files follow the MVVMC folder convention」新增的「A presentation is consumed by both the app and an extension」情境；驗證：extension target 可編譯並引用該元件，且專案中不存在第二份相同實作。
- [x] 3.3 確認 `SectorMark` 在 WidgetKit 可正確渲染（design 的風險項）；驗證：Widget 預覽中甜甜圈呈現三桶佔比與中心總數；若不可用，改以基本圖形繪出相同版面，共用元件的抽出仍保留。
- [x] 3.4 實作 extension 端的資料讀取 — 對應「The widget reads data without exposing persisted types」與「The store is reachable by every process that needs it」，落實 design 的「Widget 端的資料讀取自行建立容器，且失敗時不終止」：於 extension 內建立自己的容器（同樣不指定容器位置），讀取後轉為 Domain Model 放入 `TimelineEntry`；驗證：`TimelineEntry` 的屬性只有數量與可選金額，無任何持久化型別；Widget 顯示的數字與 app 首頁一致。
- [x] 3.5 實作失敗路徑 — 對應「The widget never terminates on failure」：容器建立或讀取失敗時回傳空 entry 並呈現首頁既有的空狀態文案，不使用 `fatalError`；驗證：**已完成，但為結構性驗證而非真實 I/O 失敗實測**——`WidgetStore.loadSummary` 有兩層 `guard let try?`（容器建立、fetch），任一失敗即回傳空 summary；extension 內無 `fatalError` 亦無 `try!`（已 grep 確認為 0）。該空 summary 走的正是 5.2 已實測過的空狀態路徑，Widget 顯示「目前沒有食材」。**未涵蓋**：真實的檔案損毀或權限失敗——模擬器上刪除 store 只會讓 app 重建一個空的，無法區分「無資料」與「讀不到」，製造真實 I/O 失敗的成本高於這條路徑的風險。
- [x] 3.6 前瞻金額行的版面處理 — 對應「The widget shows the same status figures as the home screen」的無金額情境；驗證：有金額與無金額兩種資料下，Widget 其餘內容位置不變。

## 4. Timeline 策略

- [x] 4.1 將 timeline 的下一個刷新點設為次日零時 — 對應「The timeline refreshes at each day boundary and on data change」，落實 design 的「Timeline 以每日起始為刷新點，並由 app 在資料變動時主動要求重載」；驗證：**已完成，但驗證方式已調整**——原訂「將裝置時間推進跨過午夜」不可行：模擬器時鐘跟隨 macOS 主機，實測需更動開發機系統時間，副作用遠大於這條規則的風險。改為將刷新點計算抽為 `DayBoundary.next(after:calendar:)`（置於 Domain 而非 extension 內，否則進不了測試 target），以 6 個測試釘住：一般時刻、接近午夜、正好零時（須為再隔一天，否則 timeline 立即失效而反覆刷新）、跨月、跨年，以及「回傳值必定晚於輸入」的全時段檢查。本專案能保證的是**告訴 WidgetKit 正確的刷新時間**；屆時是否真的喚醒由系統負責，不在可控範圍。
- [x] 4.2 app 端在新增、標記已使用／丟棄、刪除後要求重新載入 timeline；驗證：於 app 內完成一次標記已使用後返回主畫面，Widget 內容已更新。
- [x] 4.3 點擊行為 — 對應「Tapping the widget opens the app」；驗證：點擊 Widget 任一處開啟 app 並停在首頁。

## 5. 驗收

- [x] 5.1 視覺一致性；驗證：同一組資料下，Widget 與首頁「現況」區塊的甜甜圈比例、中心總數、legend 三行數字、前瞻金額四項皆相同。
- [x] 5.2 空狀態一致性；驗證：清空所有記錄後，Widget 顯示的文案與首頁相同。
- [x] 5.3 更新 `openspec/specs/README.md` 的 capability map，加入 `widget` 並標註其與 `persistence`、`home-ui`、`food-item` 的關係；驗證：README 可看出 Widget 的資料來自 `persistence`、呈現與 `home-ui` 共用、狀態規則來自 `food-item`。
