## Summary

把「裝置語言既非繁體中文也非英文」時的介面語言，從繁體中文改為英文。

## Motivation

`localization` 現行 requirement 的 scenario 明文規定：使用者的裝置語言不屬於已宣告的兩種語系時，「介面以 source language 呈現」——也就是繁體中文。這在 v1.0.0 只有繁中時是合理的預設，但 v1.1.0 補上英文、且 app 在 132 個地區上架後，這個選擇的後果變成：**一位日本或德國使用者下載後，看到的是滿版看不懂的繁體中文。**

落差更明顯的是商店端與 app 端不一致：App Store Connect 的 `primaryLocale` 是 `en-US`，所以那位使用者在商店頁看到的是英文介紹，下載後卻變成中文。

英文是兩種語系中唯一具國際通用性的選項。對非中文使用者而言，退到英文即使不是母語，至少是可讀的。

實測確認（模擬器，以啟動參數覆寫偏好語言）：偏好語言僅日文時，介面為繁體中文，而金額依 `ja_JP` 格式化為 `¥` ——語言與貨幣分屬兩地，比單純的語言不符更令人困惑。

## Proposed Solution

兩項改動缺一不可：

**一、宣告 fallback 為英文。** app 與 widget 兩個 target 的 `CFBundleDevelopmentRegion` 皆設為 `en`。此值刻意與 XcodeGen 的 `developmentLanguage`（維持 `zh-Hant`）不同——後者決定 String Catalog 的 source language，而字串的 key 是中文字面值，不能更動。

**二、為 source language 補上實體 catalog 條目。** 這是本 change 的關鍵，也是最違反直覺的部分：繁體中文原本**沒有**實體翻譯檔——`zh-Hant.lproj` 只有 `InfoPlist.strings`，沒有 `Localizable.strings`。中文之所以能顯示，是靠「找不到翻譯就顯示 key」的機制，而 key 恰好就是中文。

因此若只做第一項，繁中使用者也會被推向英文（已實測確認：僅改 fallback 後，偏好語言為繁中者看到英文）。為 catalog 中 80 個字串補上 `zh-Hant` 條目（值等同 key）後，`zh-Hant.lproj/Localizable.strings` 才會生成，中文不再依賴 fallback。

## Non-Goals

- 不新增第三種語系。支援語言維持繁體中文與英文兩種。
- 不變更 String Catalog 的 source language，也不把中文 key 改寫為英文 key——那需要改動每一處字面值，且與現行的字面值撰寫慣例衝突。
- 不變更 App Store Connect 的 `primaryLocale`（維持 `en-US`）。本 change 修正的是 app 端，改動後兩端方向一致。
- 不處理貨幣與日期格式。那些依使用者所在地由 FormatStyle 決定，與介面語言分屬兩件事，現行行為正確。

## Alternatives Considered

**維持現狀。** 已否決——與「全球發行」的實際上架範圍矛盾，且商店頁與 app 端語言不一致。

**把 source language 改為英文。** 需要把 81 個中文 key 全數改寫為英文，並更動每一處 `Text()` 內的字面值。工作量與破壞面遠大於收益，且 `localization` 的既有 requirement 明確選擇了「中文為 source」這個方向，本 change 無意推翻它。

## Impact

- Affected specs: `localization`
- Affected code:
  - Modified:
    - `project.yml`（app 與 widget 兩個 target 的 `CFBundleDevelopmentRegion`，widget 另補 `CFBundleLocalizations`）
    - `Sources/Resources/Localizable.xcstrings`（80 個字串補上 `zh-Hant` 條目）
- 實作狀態：**程式碼改動已完成並於模擬器驗證**（繁中顯示中文、日文顯示英文）。本 change 的作用是把已改變的決定寫回 spec，使實作與規格重新一致。
- 後續風險：`zh-Hant` 條目是 source language 的條目，形式上像是冗餘資料。若日後清理 stale 時將其刪除，繁中會再次退回英文，且**不會有任何編譯警告**。此約束需寫入 spec 與 CLAUDE.md 的 String Catalog 規則。
