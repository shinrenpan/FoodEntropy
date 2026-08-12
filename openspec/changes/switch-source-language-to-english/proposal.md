## Summary

把 String Catalog 的 source language 由繁體中文改為英文：程式碼中的字面值改用英文，中文改由 catalog 提供翻譯。

## Motivation

現行架構走的是少數派方向——中文為 source、英文為翻譯。`localization` 的 requirement 記錄了當初的理由（文案以中文撰寫、主要市場讀中文），那個理由本身沒有錯，但它帶來的代價在 2026-08-12 具體出現了一次：

繁體中文作為 source language **沒有實體翻譯檔**，`zh-Hant.lproj` 只有 `InfoPlist.strings`。中文能顯示是靠「找不到翻譯就顯示 key」的機制。因此當 fallback 改為英文之後，繁中使用者也一併被推向英文——修正方式是為 80 個字串補上「值等同 key」的 `zh-Hant` 條目，那些條目在清理 stale 時看起來完全像冗餘資料，刪掉就會靜默退化，而且沒有任何編譯警告。

換成英文 source 之後這個結構性陷阱消失：英文是 source 也是 fallback，兩者一致；中文是正規的翻譯，本來就有實體檔。此外英文 key 讓程式碼在不懂中文的協作者眼中仍可讀，也符合工具鏈的預設假設。

## Proposed Solution

**一、先拆開兩處重複的英文文案。** 新的英文 key 取自現有的 en 翻譯值，但有兩對中文的英文翻譯目前相同，直接轉換會使中文塌成同一個 key：

| 中文 | 用途 | 現行英文 | 新英文 key |
|---|---|---|---|
| 吃掉 | 浪費統計的圖表資料標籤 | Used | `Used` |
| 已使用 | 列表滑動的動作按鈕 | Used | `Mark as used` |
| 已過期 | 現況 legend 的狀態名 | Expired | `Expired` |
| 已過期未處理 | 分桶區塊標題 | Expired | `Expired, unhandled` |

拆開後英文也更精確——動作與狀態原本就不該共用同一個詞。

**二、以現有翻譯為對應表做機械轉換。** 新 key 即舊的 en 值，新的 `zh-Hant` 翻譯即舊的 key。80 個字串中 10 個含格式參數、3 個含複數變化，已確認參數數量兩邊一致，複數結構改由英文承載（英文有 one/other 之分，中文無變化）。

**三、切換 source language 與 development language。** catalog 的 `sourceLanguage` 與 XcodeGen 的 `developmentLanguage` 皆改為 `en`。`CFBundleDevelopmentRegion` 已於前一個 change 設為 `en`，屆時三者一致，不再需要「刻意讓兩者不同」的說明。

**四、移除「source language 需要實體條目」的規則。** 該約束是為中文 source 而設，改成英文 source 後 `en` 是 source 也是 fallback，不再需要。`CLAUDE.md` 與 `localization` spec 中的對應條文一併移除，避免留下已失效卻看似有效的規則。

## Non-Goals

- 不新增第四種以外的語系。支援語言維持繁體中文與英文。
- 不改變任何中文文案的用字。中文從 key 變成翻譯，內容逐字相同。
- 不改變 `InfoPlist.xcstrings`。它的 key 是系統定義的（`CFBundleDisplayName` 等），與 source language 無關。
- 不改變 App Store Connect 的 metadata 與 `primaryLocale`。
- 不趁機調整既有的英文翻譯品質，除了上述兩對必須拆開者。文案審視是另一件事，混在大範圍機械替換裡會讓 diff 無法審查。

## Alternatives Considered

**維持中文 source，僅以測試防護。** 已評估：寫一個測試驗證繁中取得到實體字串，成本遠低於本 change。已否決——測試能擋住退化，但擋不住「這個架構本身讓每個新字串都要記得補 source 條目」這件事；每次新增字串都多一道人為步驟，長期成本高於一次性轉換。

**改為英文 source 但保留中文 key 於程式碼。** 技術上不可行：key 就是程式碼中的字面值，兩者是同一個東西。

## Impact

- Affected specs: `localization`
- Affected code:
  - Modified:
    - `Sources/Resources/Localizable.xcstrings`（80 個 key 全數更換，中文轉為翻譯）
    - `Sources/Core/Components/StatusChartView.swift`
    - `Sources/Core/Components/FoodRowView.swift`
    - `Sources/Core/Ad/AdSlotView.swift`
    - `Sources/Core/Notification/NotificationService.swift`
    - `Sources/App/SceneDelegate.swift`
    - `Sources/Features/Home/HomeView.swift`
    - `Sources/Features/Settings/SettingsView.swift`
    - `Sources/Features/FoodForm/FoodFormViewModel.swift`
    - `Tests/FoodEntropyTests/FoodFormViewModelTests.swift`（兩處以 `String(localized:)` 比對標題）
    - `project.yml`（`developmentLanguage` 改為 `en`）
    - `CLAUDE.md`（移除已失效的 source language 條目規則）
- 風險：本 change 是大範圍機械替換，中途中斷會留下部分中文、部分英文的 catalog。任務因此依「先拆撞 key → 再整批轉換 → 最後切換設定」排序，每一步結束時專案皆可建置。
- 前置：無。前一個 change（`amend-language-fallback`）已將 `CFBundleDevelopmentRegion` 設為 `en`，本 change 與其方向一致而非衝突。
