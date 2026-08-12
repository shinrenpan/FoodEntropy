## 1. 宣告英文為 fallback

- [x] 1.1 於 `project.yml` 將 app 與 widget 兩個 target 的 `CFBundleDevelopmentRegion` 設為 `en`，widget 另補上 `CFBundleLocalizations`（`zh-Hant`、`en`）— 對應「Traditional Chinese is the source language and English is the translation」修改後的 fallback 條款；驗證：**已完成**——重新產生專案後，`Sources/App/Info.plist` 與 `Sources/Widget/Info.plist` 的該鍵皆為 `en`。XcodeGen 的 `developmentLanguage` 維持 `zh-Hant` 不動（它決定 String Catalog 的 source language，而 key 是中文字面值）。

## 2. 為 source language 補上實體條目

- [x] 2.1 為 `Sources/Resources/Localizable.xcstrings` 中每個字串補上 `zh-Hant` 條目，值等同 key — 對應「The source language carries its own catalog entries」；驗證：**已完成**——80 個字串補上條目（空 key 除外），補上後 catalog 的 `zh-Hant` 與 `en` 條目數分別為 80 與 81；建置後 `zh-Hant.lproj/` 由原本僅有 `InfoPlist.strings`，變為同時具備 `Localizable.strings`。
- [x] 2.2 確認 `Sources/Resources/InfoPlist.xcstrings` 無須補條目；驗證：**已完成**——該 catalog 的四個鍵（`CFBundleDisplayName`、`CFBundleName`、兩個權限描述）原本即同時具備 `zh-Hant` 與 `en` 條目，故 `zh-Hant.lproj/InfoPlist.strings` 一直存在。

## 3. 驗證兩種語系皆正確

- [x] 3.1 繁體中文使用者仍看到中文 — 對應「Entries for the source language appear redundant during cleanup」所防範的退化；驗證：**已完成**——以啟動參數覆寫偏好語言為 `zh-Hant-TW`／locale `zh_TW`，介面為中文，金額顯示 `$35`。**此項曾在僅完成第 1 節時失敗**（介面退為英文），是第 2 節存在的理由。
- [x] 3.2 非中英使用者看到英文 — 對應「A user of an unsupported language」；驗證：**已完成**——以偏好語言 `ja`／locale `ja_JP` 啟動，介面為英文。
- [x] 3.3 貨幣仍依使用者所在地格式化 — 對應「Currency and dates still follow the user's region」；驗證：**已完成**——同一筆金額在 `zh_TW` 顯示 `$35`、在 `ja_JP` 顯示 `¥35`，介面語言與貨幣格式各自獨立。
- [x] 3.4 既有測試未受影響；驗證：**已完成**——81 tests / 10 suites 全數通過。
- [x] 3.5 catalog 兩語系皆無缺漏；驗證：**已完成**——缺英文 0、缺中文 0。

## 4. 防止再次退化

- [x] 4.1 於 `CLAUDE.md` 的 String Catalog 規則補上「source language 的條目不得在清理 stale 時刪除」— 對應「Entries for the source language appear redundant during cleanup」；驗證：**已完成**——該條規則現載明每個 entry 需同時具備 `zh-Hant` 與 `en` 條目、值等同 key 的 `zh-Hant` 條目在清理 stale 時不得刪除，以及刪除後的後果（`zh-Hant.lproj` 無編譯字串檔，因 fallback 為 `en` 而使中文使用者靜默看到英文，且建置不會有任何警告）。
