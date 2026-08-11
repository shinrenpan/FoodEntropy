## Context

iOS 版 v1.1.0 已上架，30 個 Swift 檔約 2,832 行，MVVMC 分層完整：`FoodItemEntity`（`@Model`）→ `SwiftDataManager`（`toDomain()`）→ ViewModel → State → View。整份程式碼中唯一觸碰 SwiftData 型別的是 `SwiftDataManager` 與 `FoodItemEntity`；ViewModel 以上只認得 `FoodItem` 這個 Domain Model。這道邊界是本次移植可行的前提。

`mvvmc-skip` 規範已存在，內含三道關卡（轉譯 / Kotlin 編譯 / 執行期）與對應眉角，本設計不重複其內容，只描述本專案特有的決策。

外部限制：Skip 目前沒有 SwiftData 或任何 ORM，只提供 SkipSQL（低階 SQLite 綁定）；SkipUI 不支援 Swift Charts、PhotosUI 與 UIKit views；Skip 沒有官方的 AdMob 模組。CloudKit 在 Android 無等價物。

## Goals / Non-Goals

**Goals:**

- 同一份 Swift 原始碼產出 iOS 與 Android 兩個 app。
- iOS 行為與移植前完全相同——包含畫面、動線、通知時機、廣告呈現。
- Android 版具備完整的核心價值：記錄食材、計算到期、到期當天通知、瀏覽與統計。
- 平台差異全部集中在條件編譯分支，分層邊界不因跨平台而移動。

**Non-Goals:**

- **Android 版不提供移除廣告的內購。** Android 需 Google Play Billing，與 StoreKit 無共用抽象；為單一平台的付費功能建立跨平台抽象層，成本高於其收益。
- **Android 版不提供 iCloud 同步。** CloudKit 是 Apple 生態專屬，Android 的等價功能需要 Firebase 或自建後端，前者牴觸 constitution 的第三方依賴限制，後者是另一個量級的工程。
- **不追求圖表的視覺完全一致。** Android 以基本圖形傳達相同資訊，不複製 Swift Charts 的動畫與互動細節。
- **不重構既有 iOS 架構。** 不為了讓兩邊「長得一樣」而移動分層邊界或改變 `doAction` 的形狀。
- **不移植 Widget 與 App Intents。** 兩者各自有獨立的 change 在排隊，且與本次移植無相依。

## Decisions

### 平台差異以條件編譯表達，不建立跨平台抽象層

平台差異一律寫成 `#if !SKIP` / `#else`，而非抽出 protocol 讓兩邊各自實作。

理由：抽象層會把差異從「一眼看得見的分支」變成「散落在多個檔案的間接呼叫」，而本專案的平台差異只有五處（持久層、廣告、通知、圖表、影像），數量不足以攤平抽象成本。更關鍵的是 `mvvmc-skip` 的核心前提是 iOS 零改動——引入 protocol 就等於改動 iOS 側的呼叫形狀，違反該前提。

替代方案：為持久層定義 `FoodStore` protocol，iOS 與 Android 各自實作。已否決，理由如上；`toDomain()` 已經提供了足夠的邊界，不需要再包一層。

### Android 持久層以 SkipSQL 手寫 CRUD，維持 toDomain() 邊界

新增與 `SwiftDataManager` 對等的 SQLite 實作，對外暴露相同的方法名稱與相同的回傳型別（`FoodItem` 及其陣列）。`SwiftDataManager` 整檔以 `#if !SKIP` 隔離，Android 分支改用新實作。

Schema 以手寫 SQL 建立，欄位對齊 `FoodItemEntity` 的屬性；`imageData` 直接存 BLOB，不做 external storage（Android 無對應機制，且圖片已在寫入前壓縮至 100–300KB）。

理由：Skip 無 ORM，這是唯一路徑。維持相同的方法簽章可讓 `SceneDelegate` 的組裝與所有 ViewModel 不必修改。

### AdMob 以 Kotlin 互操作橋接 Android SDK

`BannerAdView` 的 iOS 分支保留 `UIViewRepresentable` 包裝，Android 分支以 Skip 的 Kotlin 互操作直接呼叫 Google Mobile Ads Android SDK，包成 SwiftUI View。廣告單元 ID 與 App ID 依平台分別設定。

理由：Skip 無官方 AdMob 模組，別無他法。這是本次移植唯一沒有現成路徑的部分，因此在階段安排上被提前到第二階段驗證。

### 到期通知在 Android 以原生排程實作

`NotificationService` 的公開方法（排程、取消、前景對帳）維持相同簽章，iOS 分支保留 `UNUserNotificationCenter`，Android 分支改以平台的排程與通知機制實作，觸發時間同樣是到期當天 09:00、一項一則。

理由：到期通知是本 app 的核心價值，沒有它，產品退化成一份手動清單。Android 有成熟的等價機制，實作成本遠低於其產品價值。

### 圖表在 Android 以基本圖形重繪

`StatusChartSection`（甜甜圈）與 `WasteStatsSection`（長條圖）的 Swift Charts 呼叫以 `#if !SKIP` 保留於 iOS；Android 分支以 SkipUI 支援的基本圖形繪出等價資訊。資料計算邏輯位於 ViewModel，兩邊共用，不重複。

理由：SkipUI 不支援 Swift Charts，且官方原則為「未列出者即視為不支援」。資訊傳達比視覺一致重要。

### 分三階段導入，前兩階段為驗證關卡

階段一驗證分層假設（僅首頁列表 + 假資料），階段二驗證 AdMob 橋接，階段三才進行完整移植。前兩階段各自是 gate——未通過則停止並重新評估，不進入下一階段。

理由：本次移植最大的兩個不確定性是「MVVMC 分層是否真能無痛轉譯」與「AdMob 能否橋接」。兩者都能以小成本提前驗證，而它們若失敗，後續所有工作都失去意義。Skip 的插件綁定是 eager 的，一旦綁定每次 iOS build 都會觸發轉譯，因此綁定動作安排在階段一開始、而非專案設定當下。

## Implementation Contract

**Behavior:**

- iOS：使用者可觀察的行為與移植前逐項相同——首頁三個區塊、新增／編輯表單、設定頁三個 section、到期當天 09:00 的通知、首頁底部橫幅廣告、移除廣告內購、iCloud 同步開關。
- Android：使用者可記錄食材（含名稱、購買日、到期日、選填價格、選填照片）、瀏覽分桶清單與兩張統計圖、對每筆記錄執行延長／已使用／丟棄／刪除、於到期當天 09:00 收到通知、在首頁底部看到橫幅廣告。設定頁僅呈現「關於」區塊。

**Interface / data shape:**

- Android 持久層對外方法與 `SwiftDataManager` 同名同簽章，回傳 `FoodItem` 或 `[FoodItem]`，絕不外洩任何持久化型別。
- SQLite 資料表欄位與 `FoodItemEntity` 的屬性一一對應：識別碼、名稱、購買日、到期日、狀態字串、解析時間、圖片位元組、建立時間、價格。狀態字串沿用 `RecordStatus` 的 rawValue。
- 各 HostController 的 Android 分支以 `@State` 持有 ViewModel，並於 `onAppear` 綁定 `onRoute`，將每個 route case 轉譯為 Android Router 的呼叫。

**Failure modes:**

- 持久層建立失敗時，Android 沿用 iOS 既有的降級順序：正常 → 記憶體。iOS 的 CloudKit 降級層在 Android 不存在（無 CloudKit）。
- 廣告載入失敗時，兩平台行為一致：廣告位收合，不佔用版面、不顯示錯誤。
- 通知權限被拒時，兩平台一致：不排程、不重複索取、不阻斷儲存流程。
- Android 圖片寫入失敗時，該筆記錄仍應成功儲存，僅缺圖片——與 iOS 相同。

**Acceptance criteria:**

- iOS 迴歸：移植前後在同一台裝置上逐項比對上述 iOS 行為清單，全部相同。這是硬性驗收，不是抽查。
- 兩平台皆能以 `skip app launch` 啟動並完成一次「新增食材 → 出現在清單 → 執行已使用 → 從待處理消失」的完整流程。
- Android 上排程一則到期通知後，將裝置時間推進至到期當天 09:00，通知如期出現。
- Android 首頁底部出現橫幅廣告，且無 fill 時收合。

**Scope boundaries:**

- In scope：持久層、廣告、通知、圖表、影像處理五處的 Android 分支；三個 HostController 與 Router 的 Android 分支；Skip 工具鏈與 Gradle 專案設定。
- Out of scope：IAP、iCloud 同步、Widget、App Intents、Android 平板適配、Android 版的 App Store 上架流程。

## Risks / Trade-offs

- **AdMob 橋接沒有現成路徑** → 提前至階段二單獨驗證，且在階段一之後、完整移植之前。若橋接失敗，Android 版失去唯一收益來源，屆時的決策是「無廣告發行」或「停止移植」，而非硬幹。
- **SkipSQL 無 ORM，schema 變更需手寫遷移** → 首版只有一張表、九個欄位，遷移成本可控。將建表與遷移集中在單一檔案，避免散落。
- **第三關（執行期）的問題不會產生編譯錯誤** → 嚴格套用 `mvvmc-skip` 的三條執行期規則：HostController 的 Android 分支必須以 `@State` 持有 ViewModel、`.task` 一律拆成兩個分支、`#else` 分支不使用 `[weak]`。不挑著做。
- **iOS 迴歸風險** → 每完成一個檔案的條件編譯改動即重新建置並執行 iOS，不累積到最後才驗。iOS 行為改變即視為缺陷，不接受「Android 需要」作為理由。
- **Skip 插件綁定是 eager 的** → 綁定安排在階段一開始執行，而非專案設定階段；若階段一未通過，解除綁定即可回到純 iOS 狀態。
- **String Catalog 在 Android 的對應方式尚未查證** → 列為待解問題，於階段一實作首頁時一併確認，因為首頁必然包含使用者可見字串。

## Migration Plan

1. 建立 Android 專案骨架與 Gradle 設定，此時尚未綁定 Skip 插件，iOS build 不受影響。
2. 綁定 Skip 插件，開始階段一。
3. 階段一：僅讓首頁列表跨平台，資料來源使用既有的假資料，完全不碰持久層與廣告。通過條件為兩平台皆能啟動並顯示清單，且 iOS 行為未變。
4. 階段二：驗證 AdMob 橋接。通過條件為 Android 出現橫幅廣告、無 fill 時收合。
5. 階段三：依序移植持久層、通知、圖表、影像處理、其餘畫面。
6. 回滾策略：任一階段失敗，解除 Skip 插件綁定並移除條件編譯分支即可回到純 iOS。因所有平台差異皆為 `#if !SKIP` 包裹，移除分支不影響 iOS 程式碼路徑。

## Open Questions

- Android 最低支援版本尚未決定。影響通知排程 API 的選擇與精確鬧鐘權限的處理方式，需在階段三開始前確定。
- String Catalog 的字串如何進入 Android 資源系統尚未查證，於階段一確認。
- Android 版是否需要獨立的 AdMob app 與廣告單元（目前的 App ID 與單元 ID 皆為 iOS 專用），需在階段二開始前於 AdMob 後台確認。
