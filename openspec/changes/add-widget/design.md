## Context

v1.1.0 已上架，`persistence` 的 store 位於 app 自身容器，`SwiftDataManager.init` 只傳 `cloudKitDatabase`、未指定容器位置。首頁的「現況」區塊由 `HomeView` 內的私有 `StatusChartSection` 呈現：120 點甜甜圈（`SectorMark`，中心疊上總數）加三行 legend，另有條件顯示的前瞻金額行。

Widget 是獨立 process，無法存取 app 私有容器，因此必須引入 App Group。這件事在 2026-08-11 查證前被認為需要一次高風險的手動遷移，查證後確認由 SwiftData 自動處理，但觸發條件脆弱——詳見 proposal 的技術前提一。

UI 於同日定案為「與首頁現況區塊完全相同，且共用同一份實作」。

## Goals / Non-Goals

**Goals:**

- 使用者不開啟 app 即可得知效期概況。
- Widget 與首頁的呈現永遠一致，而非在兩處各自維護相似的版面。
- 既有使用者的資料在導入 App Group 後完整保留。
- Widget 的資料在跨日與資料變動兩種情況下都是正確的。

**Non-Goals:**

- 不做 `systemSmall` 與鎖定畫面 accessory 系列。前者放不下既有版面，後者為單色渲染，兩者都需要另一套設計。
- 不做互動式 Widget。點擊僅開啟 app 首頁。
- 不在 Widget 端寫入資料。extension 只讀不寫。
- 不改變首頁既有的視覺與行為。抽出共用元件是重構，不是重新設計。
- 不涵蓋提醒、付費分層、歷史趨勢、分類標籤。

## Decisions

### 呈現層抽為共用元件，而非在 Widget 重寫一份相似版面

把 `HomeView` 內的 `StatusChartSection` 抽到 `Sources/Core/Components/`，app 與 extension 兩個 target 皆納入該檔。抽出範圍只涵蓋內容本身（甜甜圈、legend、前瞻金額行），`Section` 容器與「現況」標題留在 `HomeView`——Widget 沒有 `List` 語境，`Section` 在該處不會渲染成預期樣貌。

理由：兩份相似實作會隨時間漂移。配色、文案、無障礙處理任一處改動只發生在一邊，就會產生使用者看得見的不一致。`Sources/Core/Components/` 已有 `FoodRowView` 作為跨畫面共用元件的先例，位置慣例不需新增。

替代方案：Widget 自行以基本圖形繪製。已否決——那會立刻產生兩套需要各自維護的版面，且無法保證視覺一致。

### 不為 App Group 指定容器位置或名稱

加入 App Group entitlement 之後，`ModelConfiguration` 不得為此指定 configuration name、`url` 或 `groupContainer` identifier。

理由：SwiftData 的自動複製掛在 `groupContainer` 隱含的 `.automatic` 偵測上。任何明確指定都會繞過偵測，開出一個空 store，既有使用者的資料留在舊位置且永遠讀不到。公開資料中「自動複製無效」的回報，追查後皆為此類寫法所致，而非 framework 缺陷。

此決策的困難之處在於：正確做法的特徵是「不寫程式碼」，因此實作端沒有可供靜態檢查的痕跡。唯一的驗證方式是升級情境實測。

替代方案：明確指定 App Group URL 以求「行為可預測」。已否決——可預測的代價是既有資料全失。

### Widget 端的資料讀取自行建立容器，且失敗時不終止

extension 內建立自己的 `ModelContainer`（同樣不指定容器位置），於 timeline 產生時以 `FetchDescriptor` 讀取，轉為 Domain Model 後放入 `TimelineEntry`。建立或讀取失敗時回傳空的 entry，呈現既有的空狀態文案。

理由：`TimelineEntry` 會跨 process 傳遞，攜帶 context-bound 的 `@Model` 物件不安全，且違反憲章的分層規定；`toDomain()` 已存在，直接沿用。不以 `fatalError` 終止是因為 Widget 崩潰在使用者眼中是一塊空白磚，比顯示「目前沒有食材」更糟——這與 `persistence` 既有的降級哲學一致。

### Timeline 以每日起始為刷新點，並由 app 在資料變動時主動要求重載

timeline 的下一個刷新時間設為次日零時；app 端在新增、標記、刪除後要求重新載入。

理由：`ExpiryStatus` 是日期的函式，同一筆資料在午夜過後就換桶，因此不能只在資料變動時更新。反過來，只靠每日刷新則會讓使用者在 app 內操作後看到過期的 Widget，兩者都需要。

## Implementation Contract

**Behavior:**

- 使用者在主畫面加入中尺寸的「食熵」Widget 後，看到與 app 首頁「現況」區塊相同的內容：甜甜圈呈現三桶佔比、中心為總數、右側 legend 列出三桶的名稱與數量；有可計算的前瞻金額時，下方多一行金額提示。
- 沒有任何食材時，Widget 顯示與首頁相同的空狀態文案。
- 點擊 Widget 開啟 app 並停在首頁。
- 跨過午夜後，Widget 的分桶結果反映新的日期，無需使用者開啟 app。
- 在 app 內新增食材、標記已使用／丟棄、或刪除之後，Widget 的內容隨之更新。

**Interface / data shape:**

- 共用元件接受三個桶的數量與一個可選的前瞻金額，不接受任何持久化型別，也不自行讀取資料。
- `TimelineEntry` 攜帶顯示所需的數值與可選金額，不攜帶 `@Model` 物件。
- Widget extension 與 app 宣告同一個 App Group identifier。
- 首頁的呈現改由共用元件負責，`HomeView` 保留 `Section` 容器與「現況」標題。

**Failure modes:**

- Widget 端建立容器或讀取失敗：回傳空 entry，呈現空狀態文案，不終止 process。
- App Group 自動複製失敗：app 端沿用 `persistence` 既有的降級順序，優先確保能啟動且既有資料可讀，不得靜默開出空 store。
- 前瞻金額不可計算時：該行不渲染，不顯示金額為零。

**Acceptance criteria:**

- 升級實測：以已有資料的 v1.1.0 build 直接升級為加了 App Group entitlement 的 build，資料仍在；iCloud 同步開啟與關閉各驗一次。
- 視覺一致：同一組資料下，Widget 與首頁「現況」區塊的甜甜圈比例、總數、legend 三行數字、前瞻金額皆相同。
- 首頁迴歸：抽出共用元件後，首頁該區塊的視覺、Dynamic Type 縮放行為、VoiceOver 朗讀內容與抽出前相同。
- 跨日正確性：將裝置時間推進跨過午夜，Widget 的分桶結果隨之改變。
- 資料變動：於 app 內完成一次標記已使用後，Widget 內容更新。

**Scope boundaries:**

- In scope：共用元件抽出、Widget extension target、App Group entitlement、timeline 策略、首頁改為引用共用元件。
- Out of scope：`systemSmall`、鎖定畫面 accessory、互動式 Widget、Widget 端寫入、首頁其餘兩個區塊（浪費統計、分桶清單）、`SwiftDataManager` 的邏輯修改。

## Risks / Trade-offs

- **自動複製失敗導致既有使用者資料遺失** → 動工前先做升級實測，未通過則不進行後續實作。iCloud 同步預設關閉，多數使用者無雲端可回復，因此此實測是 gate 而非檢查項。
- **實作端無法靜態檢查「沒有指定容器」** → 將此約束寫入 `persistence` 的 requirement，使其成為 spec 層級的規範而非口頭慣例；未來任何為 Widget 而調整容器設定的嘗試都會與 spec 衝突。
- **抽出共用元件時破壞首頁既有行為** → 抽出屬純重構，不得同時調整視覺；以首頁迴歸作為驗收條件，特別確認 Dynamic Type 縮放與 VoiceOver 朗讀。
- **`SectorMark` 在 WidgetKit 的行為未經本專案驗證** → 於 Widget 實作的第一步即確認甜甜圈能正確渲染；若不可用，退回以基本圖形繪製相同版面，此時共用元件的抽出仍然有效。
- **前瞻金額行的高度變動** → Widget 高度固定，預留該行空間，避免有無金額時版面跳動。

## Migration Plan

1. 於 Apple Developer 後台建立 App Group identifier。
2. 執行升級實測（見驗收條件）。**未通過則停止**，回到 proposal 重新評估資料傳遞方式。
3. 抽出共用元件並確認首頁迴歸通過。
4. 建立 Widget extension target，接上資料與 timeline 策略。
5. 回滾策略：移除 App Group entitlement 即回到原本的容器位置。由於未曾以程式碼指定容器，移除 entitlement 後 SwiftData 回到 app 私有容器；但此時使用者在 App Group 期間新增的資料將留在 group container，因此回滾只在升級實測階段可行，上架後不可逆。

## Open Questions

- App Group identifier 的命名尚未決定，需與既有的 bundle identifier 慣例一致。
- 升級實測若顯示自動複製在 CloudKit 開啟時行為不同，需決定是否對兩種情況採取不同處置——此問題在實測前無法回答。
