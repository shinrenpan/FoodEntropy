## 1. 拆開重複的英文文案（現行架構下，低風險）

- [x] 1.1 於 `Sources/Resources/Localizable.xcstrings` 將「已使用」的 `en` 值由 `Used` 改為 `Mark as used`，「已過期未處理」由 `Expired` 改為 `Expired, unhandled` — 對應「A translated word is not reused across different meanings」，落實 design 的「先拆開重複的英文文案，再做整批轉換」；驗證：**已完成**——catalog 中 `en` 值重複數為 0，「吃掉」仍為 `Used`、「已過期」仍為 `Expired`。
- [x] 1.2 建置並確認英文畫面的兩處改動；驗證：**已完成，但改以編譯產物驗證**——那兩處分別需左滑與捲動才看得到，截圖無法涵蓋。改為檢查 `en.lproj/Localizable.strings`：`已使用` → `Mark as used`、`已過期未處理` → `Expired, unhandled`，且 `吃掉` → `Used`、`已過期` → `Expired` 未受影響。以英文啟動的畫面其餘文案不變。

## 2. 整批轉換 catalog 與程式碼

- [x] 2.1 以腳本產生「舊中文 key → 新英文 key」對應表並改寫 catalog — 落實 design 的「以腳本產生新 catalog，而非逐條手改」與「複數變化改由英文承載」：新 key 取自舊 `en` 值，新 `zh-Hant` 值取自舊 key，`en` 條目移除（英文成為 source）；三個含複數變化者其 one/other 結構移至英文 key；驗證：**已完成**——key 數 80、重複 0、具 `zh-Hant` 翻譯 80／80、key 中含中文者 0。一般字串不再保留 `en` 條目（key 即英文），僅三個複數條目保留 `en` 的 one／other 結構（key 只能表達其中一種形式）。`sourceLanguage` 一併於本步改為 `en`——與 3.1 分開執行會產生「key 為英文但仍宣告中文為 source」的中間狀態，該狀態下英文使用者會 fallback 到中文。
- [x] 2.2 以對應表替換 8 個原始碼檔中的使用者可見字面值 — 落實 design 的「程式碼字面值以對應表替換，並以編譯失敗作為安全網」：以完整字串比對，不使用部分比對（避免「已過期」誤傷「已過期未處理」）；涵蓋 `Sources/Core/Components/StatusChartView.swift`、`Sources/Core/Components/FoodRowView.swift`、`Sources/Core/Ad/AdSlotView.swift`、`Sources/Core/Notification/NotificationService.swift`、`Sources/App/SceneDelegate.swift`、`Sources/Features/Home/HomeView.swift`、`Sources/Features/Settings/SettingsView.swift`、`Sources/Features/FoodForm/FoodFormViewModel.swift`；驗證：以 grep 掃描上述檔案，`Text("`、`String(localized:`、`Label("`、`.value("` 內不再出現中文字元。
- [x] 2.3 更新 `Tests/FoodEntropyTests/FoodFormViewModelTests.swift` 中兩處 `String(localized:)` 的比對字串為對應英文；驗證：**已完成**——兩處改為 `String(localized: "Edit Food")` 與 `String(localized: "Add Food")`，測試通過。
- [x] 2.4 **驗證無遺漏** — 對應 design 的失敗模式「字面值替換遺漏不會被編譯擋下」；驗證：**已完成**——全專案掃描後，呈現呼叫內不再有中文字面值。過程中誤將 `Tests/FoodEntropyTests/FoodStatusSummaryTests.swift` 的測試假資料（食材名稱「今天到期」恰與某個 catalog key 同名）一併替換，已還原；此為「字串比對無法區分使用者可見字串與測試資料」的實例，其餘測試檔經逐一檢視未受影響。診斷訊息（`AppRouter` 的 assertion）與 DEBUG-only 的 mock 名稱本就不在 catalog，維持中文，符合既有規範。

## 3. 切換 source language 設定

- [x] 3.1 將 catalog 的 `sourceLanguage` 與 `project.yml` 的 `developmentLanguage` 皆改為 `en` — 此步驟同時移除「Traditional Chinese is the source language and English is the translation」並實現「English is the source language and Traditional Chinese is the translation」；驗證：**已完成**——`sourceLanguage` 已於 2.1 一併改為 `en`（理由見該任務），本步改 `project.yml` 的 `developmentLanguage`；三處（含 app 與 widget 的 `CFBundleDevelopmentRegion`）皆為 `en`。同時修正 `project.yml` 中一段已過時的註解——它原本說明「刻意與 developmentLanguage 不同」，該理由已不成立。
- [x] 3.2 建置並確認 catalog 未被 Xcode 重新整理而改動 key — 對應 design 的風險項；驗證：**已完成**——建置前後 catalog 皆為 81 個 key（含空 key），無新增亦無消失，`sourceLanguage` 維持 `en`。`en.lproj` 具 `Localizable.strings` 與 `Localizable.stringsdict`（複數規則），`zh-Hant.lproj` 具 `Localizable.strings`（中文無複數變化，故無 stringsdict）。

## 4. 實測與驗收

- [x] 4.1 繁體中文文案逐項不變 — 對應「A Traditional Chinese user sees Chinese」；驗證：**已完成**——「首頁／現況／已過期／3 天內到期／保存期限內／項／至少 $125 即將到期／浪費統計／清除／浪費率／吃掉 4／丟棄 1／近 30 天內標記「已使用」與「丟棄」的統計。／已過期未處理／新增食材／設定」逐項與轉換前相同。中文現為翻譯，key 為英文。
- [x] 4.2 非中英使用者仍看到英文 — 對應「A user of an unsupported language」；驗證：**已完成**——介面為英文（Home／Current／Expired／Expiring within 3 days／Fresh／Waste Stats 等），金額為 `¥125`，語言與貨幣各自依規則決定。
- [x] 4.3 既有測試全數通過；驗證：**已完成**——81 tests／10 suites 全數通過，與轉換前相同。

## 5. 移除已失效的規則

- [x] 5.1 自 `CLAUDE.md` 的 String Catalog 規則移除「`zh-Hant` 條目值等同 key、不得於清理 stale 時刪除」一段 — 對應「The source language carries its own catalog entries」的 REMOVED 理由，落實 design 的「移除已失效的規則，而非留著備用」；驗證：**已完成**——該條規則不再提及「值等同 key」與「不得刪除」，改為載明英文是 source language、程式碼字面值為英文、每個條目具備 `zh-Hant` 翻譯，並要求 `sourceLanguage`／`developmentLanguage`／`CFBundleDevelopmentRegion` 三者保持一致（附理由：不一致時 source language 的使用者會被靜默導向 fallback，且無編譯警告）。
