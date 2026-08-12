## Context

`Localizable.xcstrings` 目前有 81 個條目（含一個空 key），source language 為 `zh-Hant`，每個條目都有 `en` 翻譯，並在 2026-08-12 補上了「值等同 key」的 `zh-Hant` 條目。程式碼中的字面值是中文，散在 8 個原始碼檔與 2 處測試。

`CFBundleDevelopmentRegion` 已於 `amend-language-fallback` 設為 `en`；`developmentLanguage`（XcodeGen）與 catalog 的 `sourceLanguage` 仍是 `zh-Hant`。

轉換的資料來源是現成的：新 key 即目前的 `en` 值，新的中文翻譯即目前的 key。已驗證 10 個含格式參數的條目其參數數量兩邊一致，且僅有兩對條目的英文值重複。

## Goals / Non-Goals

**Goals:**

- 英文成為 source language，程式碼字面值為英文。
- 中文顯示內容逐字不變。
- 轉換過程中的每個階段結束時，專案皆可建置且測試通過。
- 移除「source language 需要實體條目」這條隨舊架構而生的規則。

**Non-Goals:**

- 不調整既有英文翻譯的品質，兩處必須拆開者除外。
- 不改變中文用字。
- 不動 `InfoPlist.xcstrings`。
- 不新增語系。

## Decisions

### 先拆開重複的英文文案，再做整批轉換

「吃掉／已使用」與「已過期／已過期未處理」兩對的英文翻譯目前皆相同。若直接轉換，兩個中文會對應到同一個新 key，中文從此無法分辨。

因此第一步是在**現行架構下**修改那兩處的英文翻譯（`已使用` → `Mark as used`、`已過期未處理` → `Expired, unhandled`）。此時 key 仍是中文，改的只是 `en` 的值，屬低風險且可獨立驗證的變更。

替代方案：轉換時直接指定新 key。已否決——那會讓對應表出現「不是來自現有翻譯」的特例，而整批轉換的可信度正建立在「對應表完全來自現有資料」這一點上。

### 以腳本產生新 catalog，而非逐條手改

轉換規則單純且一致：新 key = 舊 `en` 值；新 `zh-Hant` 值 = 舊 key；新 `en` 條目不再需要（英文成為 source）。80 個條目手改必然出錯，且無法驗證覆蓋率。

腳本同時輸出「舊中文 → 新英文」對應表，供下一步替換程式碼字面值使用，兩者因此共用同一份事實來源。

### 程式碼字面值以對應表替換，並以編譯失敗作為安全網

替換以完整字串比對進行，不使用部分比對，避免「已過期」誤傷「已過期未處理」。

替換後若有遺漏，該字面值會變成 catalog 中不存在的 key——這**不會**產生編譯錯誤，只會在畫面上顯示中文原文。因此不能只靠編譯，須以「catalog 中不存在的字面值數為零」作為驗證條件。

### 複數變化改由英文承載

三個含複數變化的條目，目前中文 key 無變化、英文有 one/other 之分。轉換後英文成為 source，複數規則自然落在英文 key 上；中文翻譯為單一字串，符合中文無複數變化的事實。

### 移除已失效的規則，而非留著備用

`amend-language-fallback` 在 `localization` spec 與 `CLAUDE.md` 中新增了「source language 必須有自己的 catalog 條目」。該規則的前提是「source 不是 fallback」；本 change 之後兩者同為 `en`，規則失去適用對象。

留著它的代價是：未來讀者無法判斷它是否仍然有效，而一條無法判斷有效性的規則比沒有規則更糟。

## Implementation Contract

**Behavior:**

- 繁體中文使用者（含港澳）看到的每一句文案與轉換前逐字相同。
- 英文使用者看到的文案與轉換前相同，唯二例外為刻意拆開的兩處：列表滑動的動作按鈕由 `Used` 改為 `Mark as used`，分桶標題由 `Expired` 改為 `Expired, unhandled`。
- 非中英使用者看到英文（`amend-language-fallback` 已確立的行為，本 change 不改變）。

**Interface / data shape:**

- `Localizable.xcstrings` 的 `sourceLanguage` 為 `en`；每個條目的 key 為英文，並具備 `zh-Hant` 翻譯。
- 程式碼中所有使用者可見字面值為英文，且與 catalog 的 key 逐字相符。
- `project.yml` 的 `developmentLanguage` 為 `en`。

**Failure modes:**

- 字面值替換遺漏：該字串成為 catalog 中不存在的 key，畫面顯示中文原文，且不產生編譯錯誤。驗證條件因此定為「程式碼中的使用者可見字面值皆能在 catalog 找到對應 key」。
- 對應表撞 key：兩個不同中文對應同一英文，導致中文塌陷。已於第一步拆開，並以「新 key 數等於舊 key 數」驗證無其他碰撞。

**Acceptance criteria:**

- catalog 的 key 數量在轉換前後相同（80，不計空 key），且無重複。
- 每個條目皆有 `zh-Hant` 翻譯，缺漏數為零。
- 程式碼中不再存在中文的使用者可見字面值。
- 以偏好語言 `zh-Hant-TW` 啟動，畫面文案與轉換前的截圖逐項相同。
- 以偏好語言 `ja` 啟動，畫面為英文。
- 既有測試全數通過（含兩處改為比對英文標題者）。

**Scope boundaries:**

- In scope：`Localizable.xcstrings`、8 個原始碼檔的字面值、2 處測試引用、`project.yml` 的 `developmentLanguage`、`localization` spec、`CLAUDE.md` 的 String Catalog 規則。
- Out of scope：`InfoPlist.xcstrings`、App Store Connect metadata、`CFBundleDevelopmentRegion`（已為 `en`）、英文文案品質審視、新增語系。

## Risks / Trade-offs

- **中途中斷會留下半中半英的 catalog** → 任務排序為「拆撞 key → 整批轉換 → 切換設定」，前兩步之間與之後皆可建置；轉換本身由腳本一次完成，不存在部分完成的狀態。
- **字面值遺漏不會被編譯擋下** → 以「catalog 中找不到的字面值數為零」作為明確驗證條件，而非依賴建置成功。
- **英文文案在兩處改變** → 屬刻意且為改善（動作與狀態不再共用同一個詞），已於 proposal 與 spec 記錄。
- **Xcode 可能在下次 build 時重新整理 catalog 格式** → 轉換後立即建置一次並確認 key 未被更動，再進行後續步驟。

## Migration Plan

1. 在現行架構下拆開兩處重複的英文翻譯，建置驗證。
2. 以腳本產生新 catalog 與對應表，替換程式碼字面值與測試引用。
3. 切換 `sourceLanguage` 與 `developmentLanguage` 為 `en`，建置並跑測試。
4. 以繁中與日文兩種偏好語言實測畫面。
5. 更新 `localization` spec 與 `CLAUDE.md`，移除已失效的 source language 條目規則。
6. 回滾策略：本 change 的所有改動皆在版控內且無資料遷移，回滾即還原 commit。

## Open Questions

無。轉換規則、撞 key 的處置、驗證條件均已於本文件定案。
