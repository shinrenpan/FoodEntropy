## 1. 拆開重複的英文文案（現行架構下，低風險）

- [ ] 1.1 於 `Sources/Resources/Localizable.xcstrings` 將「已使用」的 `en` 值由 `Used` 改為 `Mark as used`，「已過期未處理」由 `Expired` 改為 `Expired, unhandled` — 對應「A translated word is not reused across different meanings」，落實 design 的「先拆開重複的英文文案，再做整批轉換」；驗證：catalog 中 `en` 值無重複（以值分組後每組筆數皆為 1），且「吃掉」仍為 `Used`、「已過期」仍為 `Expired`。
- [ ] 1.2 建置並確認英文畫面的兩處改動；驗證：以偏好語言 `en` 啟動，列表左滑的動作按鈕顯示 `Mark as used`，分桶標題顯示 `Expired, unhandled`；其餘文案不變。

## 2. 整批轉換 catalog 與程式碼

- [ ] 2.1 以腳本產生「舊中文 key → 新英文 key」對應表並改寫 catalog — 落實 design 的「以腳本產生新 catalog，而非逐條手改」與「複數變化改由英文承載」：新 key 取自舊 `en` 值，新 `zh-Hant` 值取自舊 key，`en` 條目移除（英文成為 source）；三個含複數變化者其 one/other 結構移至英文 key；驗證：轉換後 key 數為 80（不計空 key）且無重複，每個條目皆有 `zh-Hant` 條目，缺漏數為零。
- [ ] 2.2 以對應表替換 8 個原始碼檔中的使用者可見字面值 — 落實 design 的「程式碼字面值以對應表替換，並以編譯失敗作為安全網」：以完整字串比對，不使用部分比對（避免「已過期」誤傷「已過期未處理」）；涵蓋 `Sources/Core/Components/StatusChartView.swift`、`Sources/Core/Components/FoodRowView.swift`、`Sources/Core/Ad/AdSlotView.swift`、`Sources/Core/Notification/NotificationService.swift`、`Sources/App/SceneDelegate.swift`、`Sources/Features/Home/HomeView.swift`、`Sources/Features/Settings/SettingsView.swift`、`Sources/Features/FoodForm/FoodFormViewModel.swift`；驗證：以 grep 掃描上述檔案，`Text("`、`String(localized:`、`Label("`、`.value("` 內不再出現中文字元。
- [ ] 2.3 更新 `Tests/FoodEntropyTests/FoodFormViewModelTests.swift` 中兩處 `String(localized:)` 的比對字串為對應英文；驗證：該檔不再含中文字面值，且兩個測試通過。
- [ ] 2.4 **驗證無遺漏** — 對應 design 的失敗模式「字面值替換遺漏不會被編譯擋下」；驗證：蒐集程式碼中所有使用者可見字面值，逐一比對是否存在於 catalog 的 key 集合，不存在者數量為零。

## 3. 切換 source language 設定

- [ ] 3.1 將 catalog 的 `sourceLanguage` 與 `project.yml` 的 `developmentLanguage` 皆改為 `en` — 此步驟同時移除「Traditional Chinese is the source language and English is the translation」並實現「English is the source language and Traditional Chinese is the translation」；驗證：兩處值皆為 `en`，且與既有的 `CFBundleDevelopmentRegion`（`en`）三者一致。
- [ ] 3.2 建置並確認 catalog 未被 Xcode 重新整理而改動 key — 對應 design 的風險項；驗證：建置後 catalog 的 key 集合與 2.1 產出的相同，`zh-Hant.lproj/Localizable.strings` 與 `en.lproj/Localizable.strings` 皆存在。

## 4. 實測與驗收

- [ ] 4.1 繁體中文文案逐項不變 — 對應「A Traditional Chinese user sees Chinese」；驗證：以偏好語言 `zh-Hant-TW`、locale `zh_TW` 啟動，首頁「現況」「浪費統計」「三個分桶」的文案與轉換前截圖逐項相同。
- [ ] 4.2 非中英使用者仍看到英文 — 對應「A user of an unsupported language」；驗證：以偏好語言 `ja`、locale `ja_JP` 啟動，介面為英文，金額仍以 `¥` 呈現。
- [ ] 4.3 既有測試全數通過；驗證：測試總數不低於轉換前的 81，且全數通過。

## 5. 移除已失效的規則

- [ ] 5.1 自 `CLAUDE.md` 的 String Catalog 規則移除「`zh-Hant` 條目值等同 key、不得於清理 stale 時刪除」一段 — 對應「The source language carries its own catalog entries」的 REMOVED 理由，落實 design 的「移除已失效的規則，而非留著備用」；驗證：該節不再提及「值等同 key」與「不得刪除」，改為要求每個條目具備英文 key 與中文翻譯。
