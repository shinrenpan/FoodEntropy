## Context

專案的原文語言是繁體中文——程式碼裡直接寫中文字串，建置時由 `SWIFT_EMIT_LOC_STRINGS` 自動抽取進 String Catalog，再翻成英文。這與「以英文為原文、翻成其他語言」的常見做法相反，但符合這個專案的實際情況：作者以中文思考產品文案，主要市場是繁體中文使用者，英文是為了全球上架而補的第二語言。

v1.0.0 的 `Localizable.xcstrings` 有 96 個字串、全部具備英文翻譯；`InfoPlist.xcstrings` 另外承載顯示名稱與兩個權限描述。

## Goals / Non-Goals

**Goals:**
- 記錄原文語言為繁體中文的取向。
- 記錄自動抽取的機制與它對寫法的影響。
- 記錄權限描述必須另外在地化的原因。
- 記錄格式化交由系統的界線。
- 記錄刻意不翻譯的三類字串。

**Non-Goals:**
- 無行為變更。
- 不涵蓋 `app-store-listing` 的線上文案與發行區域、各畫面的文案內容。

## Decisions

### 原文語言是繁體中文，英文為翻譯目標

String Catalog 的來源語言設為繁體中文，程式碼中直接寫中文字面值。理由：作者以中文構思文案，若強制先寫英文再翻回中文，中文（主要市場語言）反而成了轉譯品，語感會失真。代價是英文那一側全是翻譯，需要額外檢查是否自然。

### 依賴建置期自動抽取，因此字面值必須寫在可被辨識的位置

`SWIFT_EMIT_LOC_STRINGS` 開啟後，SwiftUI 的 `Text` 等接受 `LocalizedStringKey` 的位置可以直接寫中文字面值並被自動抽取；非 View 層則必須明確以 `String(localized:)` 包裹才會進入 Catalog。理由：`LocalizedStringKey` 與 `String` 是不同型別，只有前者會被自動處理。這個差異決定了同一句中文在 View 與 ViewModel 裡要用不同寫法——不是風格選擇，而是會不會被翻譯的分野。

### Info.plist 的字串走獨立的 Catalog

顯示名稱與相機、相簿的權限描述放在 `InfoPlist.xcstrings`。理由：這些字串由系統在 app 之外呈現（權限彈窗、主畫面圖示下方），不經過程式碼，因此不會被 `SWIFT_EMIT_LOC_STRINGS` 抽取，必須另外提供。漏掉它們的後果是英文使用者看到中文的權限說明——那是最需要被理解的一句話。

### 金額與日期交由系統格式化，不自行組字串

價格直接使用 StoreKit 商品的顯示價格；日期與數字使用系統格式化。理由：貨幣符號的位置、小數點與千分位、日期的年月日順序都隨地區而異，手工組字串必然在某個地區出錯，而且錯誤只有該地區的使用者看得到。把格式化交給系統也表示這些值不需要進 String Catalog。

### 使用者輸入的資料不翻譯

食材名稱等使用者輸入的內容原樣呈現。理由：那是使用者的資料，不是 app 的文案。這一點在通知內容中特別明顯——通知的模板句走 String Catalog，中間插入的食材名稱維持原樣。

### 三類字串刻意不進 String Catalog

其一，開發者診斷訊息（`assertionFailure`、`fatalError` 的說明）。理由：只有開發者在 Xcode 中看得到，翻譯它們會讓錯誤訊息無法用固定字串搜尋，也讓報錯內容依開發機語系而變。

其二，DEBUG 模式下的 mock 資料（種子食材名稱）。理由：它們是測試資料而非文案，且在 Release 建置中根本不存在。

其三，URL scheme 與 deeplink 字串。理由：那是協定的一部分，翻譯會直接讓路由失效。

## Implementation Contract

**Behavior (observable):**
- 系統語言為繁體中文時，介面全中文；設為英文時，介面全英文。
- 權限彈窗的說明文字跟隨系統語言。
- 主畫面的 app 名稱跟隨系統語言。
- 價格依使用者的地區顯示對應的貨幣符號與格式。
- 食材名稱在任何語言設定下都原樣顯示。
- 通知內容的固定部分跟隨語言，食材名稱不變。

**Interface / data shape:**
- `Sources/Resources/Localizable.xcstrings`：來源語言繁體中文，含英文翻譯。
- `Sources/Resources/InfoPlist.xcstrings`：承載顯示名稱、相機與相簿權限描述。
- `project.yml`：`developmentLanguage` 為繁體中文；`CFBundleLocalizations` 宣告繁體中文與英文；`SWIFT_EMIT_LOC_STRINGS` 開啟。
- View 層：接受 `LocalizedStringKey` 的位置直接寫中文字面值。
- 非 View 層：以 `String(localized:)` 包裹。

**Acceptance criteria:**
- `Localizable.xcstrings` 中沒有缺少英文翻譯的條目。
- `InfoPlist.xcstrings` 涵蓋顯示名稱與兩個權限描述，且皆有兩種語言。
- ViewModel、Service 與 Manager 層中，面向使用者的中文字串皆以 `String(localized:)` 包裹；未包裹的中文字串僅限診斷訊息、`#if DEBUG` 內的 mock 資料與註解。
- Domain 層不含任何面向使用者的文案。
- 程式碼中無自行組成的貨幣或日期格式字串。

**Scope boundaries:**
- In scope：原文語言與支援語言、抽取機制與寫法要求、Info.plist 在地化、格式化歸屬、使用者資料不翻譯、三類不翻譯字串。
- Out of scope：App Store 線上文案與發行區域（`app-store-listing`）、各畫面的文案內容、未來新增語言的流程。

## Risks / Trade-offs

- [以中文為原文語言] → 英文側全為翻譯，品質取決於翻譯當下的判斷，且沒有母語者審閱流程。英文市場的文案自然度是未經驗證的。
- [View 與非 View 層的寫法不同] → 同一句話在兩處要用不同寫法，容易在把邏輯從 View 搬到 ViewModel 時漏掉 `String(localized:)`，而漏掉的後果是該句永遠不會被翻譯，且不會有任何建置警告。
- [僅支援兩種語言] → `CFBundleLocalizations` 明確宣告後，其他語言的使用者一律看到繁體中文（原文語言）而非英文。對非中文、非英文的使用者而言，這比 fallback 到英文更難理解。
- [診斷訊息含中文] → 若未來有非中文的協作者或需要把錯誤訊息貼給外部工具分析，中文診斷訊息會造成障礙。
