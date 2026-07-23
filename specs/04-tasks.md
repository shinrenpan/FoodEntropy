# 04 — 實作任務拆解

> 狀態：✅ 定案（可據此開工）
> 上游：`01-navigation.md`、`02-architecture.md`、`03-screens/*.md`

依相依性分階段。每項標註對應 spec。建議逐階段完成、可獨立驗證後再往下。
架構規範以既有 skills 為準：`mvvmc-model` / `mvvmc-viewmodel` / `mvvmc-view` / `mvvmc-hostcontroller` / `mvvmc-navigation` / `mvvmc-testing` / `swift-concurrency`。

---

## Phase 0 — 專案骨架

- [x] `git init` + `.gitignore`（Xcode / SPM / XcodeGen；忽略 `.xcodeproj` 與生成的 `Info.plist`）。
- [x] `brew install xcodegen`（2.46.0）。
- [x] 撰寫 `project.yml`：UIKit lifecycle（AppDelegate + SceneDelegate，MVVMC 需求）、**iOS 26**、**iPhone only**（`TARGETED_DEVICE_FAMILY=1`）、**直向鎖定**、Bundle ID `com.shinrenpan.FoodEntropy`、**Swift 6 strict concurrency**、相機/相簿權限字串、`foodentropy` URL scheme。
- [x] 以 `xcodegen generate` 產生 `.xcodeproj`（不進版控）。
- [x] 專案目錄結構依 MVVMC 分層建立（`App` / `Core/{Persistence,Domain,Notification,Navigation,Extensions}` / `Features` / `Resources`）。
- [x] 三 Tab 骨架可 build + 跑（SceneDelegate → UITabBarController，佔位 View）；單元測試 target（Swift Testing）通過。
- [ ] ⏸ Capabilities（iCloud / Push / IAP）：待填 `DEVELOPMENT_TEAM` 後於 `project.yml` 宣告（需 Apple 開發者帳號）。
- [ ] ⏸ 建立 iCloud container：同上，待 Team。
- [ ] ⏸ AdMob SDK：延後至里程碑 2（Phase 9）。

> Team 未填時：模擬器可 build/run；真機 / iCloud / Push / IAP 需先填 `DEVELOPMENT_TEAM`。

## Phase 1 — 資料層（`02-architecture` §1–§3 §5）

- [x] `FoodItemEntity` `@Model`：CloudKit-safe（全欄位有預設值、無 `.unique`）、`@Attribute(.externalStorage) imageData`。
- [x] Domain：`FoodItem`、`RecordStatus`(active/consumed/wasted)、`ExpiryStatus`(fresh/nearExpiry/expired)。
- [x] `FoodItemEntity.toDomain()`（含 `statusRaw` → `RecordStatus`）。
- [x] `ExpiryStatus` 計算（daysUntil 演算法，§5）+ 單元測試（邊界 −2/−1/0/1/3/4 皆綠）。
- [x] 圖片壓縮工具 `ImageCompressor`：JPEG 0.7、長邊 1024px → `Data`（§3）。
- [x] `SwiftDataManager`（@MainActor）：
  - [x] 依 `cloudKitEnabled` 建立掛/不掛 `cloudKitDatabase` 的 ModelContainer（另支援 inMemory 測試）。UserDefaults 偏好接線於 Phase 2 App 啟動裝配。
  - [x] CRUD：`create` / `update` / `delete`(hard) / `markConsumed` / `markWasted` / `fetchActiveFoods`（排序：expiryDate↑, createdAt↑）。
  - [x] 邊界只回傳 Domain，不外洩 `@Model`。
- [x] Mock：`FoodItem.mock` / `.mocks`（`#if DEBUG`，`mvvmc-model` 規範）。

> 驗證：9 個單元測試（ExpiryStatus 邊界 + SwiftDataManager CRUD）全綠。

## Phase 2 — 導航基礎（`01-navigation` §7、`mvvmc-navigation` / `mvvmc-hostcontroller`）

- [x] `AppRouter`（stateless 中樞）：`to` / `back` / `backTo` / `backToRoot` / `sheet` / `deeplink` / `tab` + 自訂轉場（modal/fade）+ 側滑限定 `.push`。Swift 6：associated object key 改 `nonisolated(unsafe)`。
- [x] `Deeplink`（集中式路由）：scheme `foodentropy`，v1 僅 `.home`（通知點擊 → 首頁 Tab）。
- [x] `SceneDelegate` 導航裝配：UITabBarController 三分頁（各含 NavigationController）、`window.backgroundColor`、三進入點（前景/冷啟動 URL、通知點擊）、前景通知橫幅。
- [x] HostController 橋接模式確立（`mvvmc-hostcontroller`）。各 Feature 的 HostController 於 Phase 3/5/6 建立並換入 SceneDelegate（目前為佔位 View）。

> 驗證：build + 既有 9 測試通過。AppRouter 的 push/sheet 實際導航於 Phase 3 首頁接上 Form 時驗證。

## Phase 3 — 首頁（`03-screens/home.md`）

- [x] `HomeViewModel`（@Observable @MainActor）：State + `doAction`（onAppear / add / row / consume / waste / delete 確認流 / extend / edit）。以 `dataResponse(.foodsLoaded)` 為注入點。
- [x] `AdSlotView` 佔位 seam：DEBUG 顯示「Ad Placeholder」框、Release collapse。`adsRemoved`(寫死 false) 為 true 時隱藏。
- [x] `HomeView`（L1/L2/L3）：`AdSlotView` + 清單 + FAB + 空狀態 hint。
- [x] `FoodRow`：縮圖 / 名稱 / 到期資訊 / 狀態顏色（不顯示購買日）。
- [x] 滑動：leading=已使用、trailing=刪除（跳 alert 確認）；長按 context menu 完整 5 項。
- [x] 延長效期：快捷 date picker（SwiftUI sheet）→ 存。（通知重排留 Phase 7）
- [x] onAppear 重撈刷新。
- [x] `HomeHostController`（純 Router，push Form add/edit）；SceneDelegate 換入首頁正式 HostController。
- [x] ViewModel 測試（inMemory manager 驅動，9 個）。
- [x] 實機模擬器驗證：空狀態 UI 正常、深色模式、正式 store 可建立。

> 註：刪除確認 `.alert`、延長 `.sheet` 為無 VM 的輕量 UI affordance，不走 AppRouter（Router 專責畫面切換）。Form 目前為 Phase 4 佔位。

## Phase 4 — 食材 Form（`03-screens/form.md`）

- [x] `FoodFormViewModel`：Mode(add/edit)、State（含 `isSaveEnabled`）、dirty 快照比對、`doAction`、`navigationTitle`。
- [x] `FoodFormView`：名稱 TextField、購買日 / 到期日 DatePicker（到期日下限=購買日、購買日頂推到期日）、圖片區塊。
- [x] 圖片來源 confirmationDialog：拍照（`CameraPicker`）/ 相簿（`PhotosPicker`）/ 移除 / 取消 → `ImageCompressor` 壓縮存 Data。
- [x] 儲存驗證（名稱去空白非空 → Save 才可按）。
- [x] 返回放棄確認（有變更才跳；`navigationBarBackButtonHidden` + 取消鈕）。
- [x] 儲存流程：manager 寫入 → onRoute(.close) pop（首頁 onAppear 自動刷新）。**通知權限/排程留 Phase 7**。
- [x] `FoodFormHostController`（純 Router，onRoute → AppRouter.back）；`HomeHostController` 改收 manager 並傳遞。
- [x] ViewModel 測試（12 個）。
- [x] 模擬器實跑：seed mock 驗證清單/FoodRow 狀態色與排序正確（DEBUG `SEED_MOCKS` env hook）。

## Phase 5 — 分析（`03-screens/analytics.md`）

- [x] `AnalyticsViewModel`：三桶 State（expired/nearExpiry/fresh）、onAppear 分桶（`dataResponse` 注入）。
- [x] `AnalyticsView`：急→緩三 Section（header 桶名+數量、空桶顯示 0 項）、唯讀 row。
- [x] `AnalyticsHostController`（無 Router 最簡版）；SceneDelegate 換入分析。
- [x] 共用組件重構：`FoodRow` 提拔為 `FoodRowView`（首頁 + 分析共用）。
- [x] ViewModel 測試（3 個）。
- [x] 模擬器實跑驗證分桶/數量/唯讀（DEBUG `INITIAL_TAB` env hook）。

## Phase 6 — 設定（`03-screens/settings.md`）

- [x] `SettingsViewModel`：State + `doAction`（注入 UserDefaults 供測試）。
- [x] Section 購買 / 同步與通知 / 關於（3 個 L2 section）。
- [x] iCloud 開關 → 存偏好（`AppPreferenceKey`）+ 「下次啟動生效」提示。
- [x] 通知列：顯示狀態（已開啟/已關閉/未設定）+ 導向系統設定。
- [x] 隱私權政策：SFSafariViewController（經 AppRouter.sheet）。URL 為 Phase 11 待換的 placeholder。
- [x] 版本顯示（修正 Info.plist 引用 `MARKETING_VERSION` → 顯示 0.1.0）。
- [x] 購買區 UI 保留但互動 stub → 「即將推出」提示（IAP 延後，Phase 8）。
- [x] SceneDelegate 換入設定；移除 Phase 0 佔位（`Phase0PlaceholderView`、`makePlaceholderTab`）。
- [x] 4 個 SettingsViewModel 測試；模擬器截圖驗證。

## Phase 7 — 通知（`02-architecture` §8）

- [x] `NotificationService`（@MainActor，`active` 旗標供測試 no-op）：權限請求 + reconcile 排程。
- [x] 情境式請求權限：`FoodFormViewModel` 首次儲存呼叫 `requestAuthorizationIfNeeded`（notDetermined 才跳）。設定「通知」列共用。
- [x] 排程：到期日 09:00、食材 id 為 identifier、過去時間不排；`content.userInfo` 帶 `deeplink` 供點擊回首頁。
- [x] 取消/重排：以 **reconcile 策略**——每次新增/編輯/延長/刪除/已使用/丟棄後，用當前 active 清單重建排程，天然涵蓋取消與重排。
- [x] 64 則上限：reconcile 取「未過 09:00」者、依到期日升冪、取最近 60 筆（nearest-first）。
- [x] 補排時機：`SceneDelegate.sceneDidBecomeActive` 對帳（處理跨日 / 上限 / 外部變動）。
- [x] 測試：VM 注入 `NotificationService(active: false)` 保持乾淨；37 測試全綠。

## Phase 8 — IAP 移除廣告（`02-architecture` §7）— ⏸ 延後（里程碑 2）

> v1 不做；設定 UI 已 stub（Phase 6）、`adsRemoved` 已寫死 false（Phase 3）。

- [ ] StoreKit 2 產品設定（非消耗型）+ StoreKit config 檔（本地測試）。
- [ ] entitlement 查詢（`currentEntitlements`）+ `Transaction.updates` 監聽。
- [ ] 購買 / 還原流程 + 錯誤處理。
- [ ] `adsRemoved` 改由 entitlement 驅動（取代寫死值）。

## Phase 9 — 廣告 + ATT（`Spec` Production §2、`01-navigation` §2）— ⏸ 延後（里程碑 2）

> v1 以 `AdSlotView` 佔位（Phase 3）。以下為接 AdMob 時的工作。

- [ ] 換掉 `AdSlotView` 內部實作為 AdMob 首頁頂部單一 banner（標「廣告」、明顯區隔）。
- [ ] ATT 同意流程；拒絕 → 非個人化廣告 fallback。
- [ ] 空清單仍顯示廣告 + hint（`01-navigation` §2）。

## Phase 10 — iCloud 同步驗證（`02-architecture` §6）

- [x] entitlements（iCloud container + CloudKit）寫入 `project.yml`（生成 `FoodEntropy.entitlements`，不進版控）。App ID 已開 iCloud 能力、ASC App 已建。
- [x] Bundle ID / iCloud 能力於 App Store Connect 就緒（Team `VZWPMD258L`）。
- [x] 真機測試 PASS（上雲）：開同步 → 重啟 → 新增資料 → CloudKit Console（Private DB / coredata zone）確認 `CD_FoodItemEntity` 上雲。
- [x] 真機測試 PASS（下雲）：刪除重裝 → 開同步 → 資料自動下載回來。
- [x] CloudKit 推播設定（`remote-notification` 背景模式 + `aps-environment` 分 config）消除警告。
- [x] ⚠️ 已知陷阱：**Xcode Build & Run（附 debugger）會卡住 CloudKit 背景同步**（`BGSystemTaskScheduler Code=3`），需**脫離 debugger、直接開 App** 才會同步。測試時務必留意。
- [ ] 開/關同步重啟生效驗證（同一 store URL）。
- [ ] 關→開：既有本機資料自動上傳；圖片（externalStorage）同步驗證。
- [ ] 多裝置同 Apple ID 同步實測。
- [ ] **上架前將 CloudKit schema 從 Development 部署到 Production**（CloudKit Dashboard），否則正式版無法同步。
- [ ] 確認 `VersionedSchema` 接法就位（`02-architecture` §10），未來欄位只加不改。

## Phase 11 — 合規與韌性（`Spec` Production §3 §4 §5）

- [x] 隱私權政策網頁（GitHub Pages，中英雙語，`docs/privacy/`）→ https://shinrenpan.github.io/FoodEntropy/privacy ；App 內設定已連結。上架前將同一 URL 填入 App Store Connect。（接廣告後需補廣告條款）
- [ ] App Privacy 標籤（相機 / 相簿 / 通知 / 廣告識別）。
- [ ] Info.plist 權限描述字串（相機 / 相簿 / 通知 / ATT）。
- [ ] 空狀態、通知被拒引導、圖片載入失敗等錯誤處理。
- [ ] Crash：確認 Xcode Organizer 收得到（不接第三方 SDK）。
- [ ] **無障礙驗收**（`00-constitution` 品質基準）：Dynamic Type 不破版、VoiceOver 標籤、深色模式、Reduce Motion。

## Phase 12 — 上架素材（`Spec` 待確認事項）

- [ ] App 圖示、截圖、描述文案、關鍵字。
- [ ] App Store Connect 送審設定。

---

## 建議里程碑

1. **可跑的本機版**：Phase 0–5（無 IAP / 廣告 / 同步）→ 核心體驗可用。
2. **商業化與同步**：Phase 6–10。
3. **上架**：Phase 11–12。
