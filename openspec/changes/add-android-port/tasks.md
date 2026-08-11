## 1. 專案設定（尚未綁定 Skip，iOS build 不受影響）

- [ ] 1.1 建立 Android 專案骨架與 Gradle 設定，依 `mvvmc-skip` 的 `references/project-setup.md` 執行，但**不執行插件綁定**；驗證：Gradle 專案結構就位，且 `xcodebuild` 的 iOS build 時間與產物與變更前相同（未出現 `Skip` build task）。
- [ ] 1.2 確認 Android 版是否需要獨立的 AdMob app 與廣告單元；驗證：於 AdMob 後台確認現有 App ID 與單元 ID 是否為 iOS 專用——若是，建立 Android 對應項目並記錄其 ID；此為階段二的前置。

## 2. 階段一 gate：分三階段導入，前兩階段為驗證關卡（分層假設）

本節整體實現「The two unproven assumptions are validated before the bulk of the work」的第一道關卡。

- [ ] 2.1 綁定 Skip 插件，開始轉譯 — 對應「The two unproven assumptions are validated before the bulk of the work」，此處起算的兩道 gate 必須在階段三之前通過；驗證：`xcodebuild` 出現 `Skip <Module>` build task，且該 task 開始回報轉譯錯誤（有錯誤是預期的，代表插件生效）。
- [ ] 2.2 讓首頁列表跨平台，資料來源使用既有假資料，不碰持久層與廣告；依 fail-fast 順序修轉譯錯誤（`case ... where` 拆解、巢狀 leading-dot enum 提取為具型別的 let、巢狀 case 解構拆為外層 match 加內層 switch）；此步驟落實 design 的「平台差異以條件編譯表達，不建立跨平台抽象層」，對應「Platform differences are expressed as compile-time branches, not abstractions」——修正一律就地加分支，不得抽出 protocol；驗證：`Skip <Module>` task 通過，不再回報轉譯錯誤，且新增的差異全部是條件編譯分支（無新增 protocol 或 wrapper）。
- [ ] 2.3 通過 Kotlin 編譯與執行期三規則 — 對應「Runtime-only platform defects are prevented by rule, not by inspection」：所有 `doAction(.view(...))` 補上完整限定、SkipUI 未實作的元件就地補 `#else`、首頁 HostController 的 Android 分支以 `@State` 持有 ViewModel、`.task` 拆成 iOS 與 Android 兩個分支、`#else` 分支不使用 `[weak]`。三條執行期規則一律套用、不挑著做；驗證：`skip app launch --android --plain` 啟動後顯示假資料清單，且點擊互動有反應（狀態變更會重繪）。
- [ ] 2.4 **gate 判定** — 對應「iOS behaviour is unchanged by the port」：確認 iOS 行為未變；驗證：`skip app launch --ios --plain` 後逐項比對首頁三個區塊、進出表單、設定頁——全部與移植前相同。**未通過則解除插件綁定、停止並重新評估，不進入階段二。**
- [ ] 2.5 確認 String Catalog 的字串如何進入 Android 資源系統（design 的待解問題）；驗證：Android 版首頁顯示的使用者可見字串為 zh-Hant，非 key 名稱或空字串。

## 3. 階段二 gate：AdMob 以 Kotlin 互操作橋接 Android SDK

本節是「The two unproven assumptions are validated before the bulk of the work」的第二道關卡。

- [ ] 3.1 於 Android 分支以 Kotlin 互操作接上 Google Mobile Ads Android SDK，並包成 SwiftUI View；廣告單元 ID 與 App ID 依平台分別設定；驗證：Android 首頁底部出現橫幅廣告。
- [ ] 3.2 **gate 判定**：確認無 fill 時的收合行為與 iOS 一致，且 iOS 廣告行為未變；驗證：Android 在無 fill 時廣告位收合、不佔版面、不顯示錯誤；iOS 端廣告呈現與移植前相同。**未通過則決策「無廣告發行」或「停止移植」，不硬幹。**

## 4. 階段三：完整移植

- [ ] 4.1 [P] Android 持久層以 SkipSQL 手寫 CRUD，維持 toDomain() 邊界 — 對應「The persistence layer never exposes its model type」「The domain boundary is what makes the port possible and stays intact」「Storage schema is defined once per implementation and mirrors the domain shape」：新增 SQLite 實作，方法名稱與簽章對齊既有 manager，回傳 `FoodItem` 或 `[FoodItem]`，不外洩任何持久化型別；建表 SQL 與遷移集中於單一檔案，欄位對應識別碼、名稱、購買日、到期日、狀態字串、解析時間、圖片位元組、建立時間、價格，狀態沿用 `RecordStatus` 的 rawValue；`imageData` 存為 BLOB；驗證：Android 上完成「新增食材 → 出現在清單 → 重啟 app → 仍在清單」，且無任何 ViewModel 因此變更（`git diff` 不含 `Sources/Features/**/*ViewModel.swift`）。
- [ ] 4.2 [P] 影像壓縮改用 Android 原生點陣圖 API — 對應「Photo storage adapts to the platform without changing the compression contract」：長邊上限與 JPEG 品質與 iOS 相同，Android 側壓縮後的位元組直接存為 BLOB；驗證：同一張照片在兩平台儲存後的位元組數落在同一量級（100–300KB）。
- [ ] 4.3 [P] 到期通知在 Android 以原生排程實作，公開方法簽章維持不變（排程、取消、前景對帳）；驗證：Android 排程一則到期通知後，將裝置時間推進至到期當天 09:00，通知如期出現且內容為該項目名稱。
- [ ] 4.4 [P] 圖表在 Android 以基本圖形重繪：甜甜圈與長條圖的 Swift Charts 呼叫以 `#if !SKIP` 保留於 iOS，Android 分支以 SkipUI 支援的基本圖形繪出等價資訊，資料計算維持在 ViewModel 不重複；驗證：Android 首頁兩張圖顯示的數值與 iOS 相同（可比對同一組資料下的數字標籤）。
- [ ] 4.5 移除廣告內購與 iCloud 同步整檔隔離於 iOS — 對應「A capability absent on one platform is removed there, not degraded everywhere」：兩者的實作與其在設定頁的入口一併以 `#if !SKIP` 排除於 Android，iOS 側不因此弱化；驗證：Android 設定頁僅呈現「關於」區塊，無購買與同步控制項；iOS 設定頁三個 section 完整如常。
- [ ] 4.6 移植新增／編輯表單，照片選取改用 SkipKit 的媒體選擇器；驗證：Android 上可新增含照片的食材，照片顯示於表單與清單。
- [ ] 4.7 補齊各 HostController 與 Router 的 Android 分支：以 `@State` 持有 ViewModel、`onAppear` 綁定 `onRoute`，將每個 route case 轉譯為 Android Router 呼叫，範本見 `mvvmc-skip` 的 `references/android-router.md`；驗證：Android 上可在首頁、表單、設定之間往返，返回後畫面狀態正確。
- [ ] 4.8 對齊持久層失敗時的降級行為：Android 為「正常 → 記憶體」兩層（無 CloudKit 層）；驗證：以無法寫入的儲存路徑啟動 Android app，app 仍能開啟並可操作，資料不落地但不崩潰。

## 5. 驗收

- [ ] 5.1 iOS 迴歸逐項比對 — 對應「iOS behaviour is unchanged by the port」；驗證：首頁三個區塊、新增與編輯表單、設定頁三個 section、到期當天 09:00 的通知、首頁橫幅廣告、移除廣告內購、iCloud 同步開關——全部與移植前相同。此為硬性驗收，不抽查。
- [ ] 5.2 兩平台完整流程驗證；驗證：`skip app launch --ios --plain` 與 `skip app launch --android --plain` 皆能完成「新增食材 → 出現在清單 → 執行已使用 → 從待處理消失」。
- [ ] 5.3 更新 `openspec/specs/README.md` 的 capability map，加入 `cross-platform` 並標註其與 `persistence`、`advertising`、`notification`、`home-ui` 的關係；驗證：README 可看出哪些 capability 具有平台差異，以及差異的表達方式。
