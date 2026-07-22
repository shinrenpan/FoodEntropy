# 04 — 實作任務拆解

> 狀態：✅ 定案（可據此開工）
> 上游：`01-navigation.md`、`02-architecture.md`、`03-screens/*.md`

依相依性分階段。每項標註對應 spec。建議逐階段完成、可獨立驗證後再往下。
架構規範以既有 skills 為準：`mvvmc-model` / `mvvmc-viewmodel` / `mvvmc-view` / `mvvmc-hostcontroller` / `mvvmc-navigation` / `mvvmc-testing` / `swift-concurrency`。

---

## Phase 0 — 專案骨架

- [x] `git init` + `.gitignore`（Xcode / SPM / XcodeGen）。
- [ ] `brew install xcodegen`。
- [ ] 撰寫 `project.yml`：SwiftUI App target、**iOS 26+**、**iPhone only**、**直向鎖定**、Bundle ID / Team、Swift Concurrency **strict**、String Catalog。
- [ ] 以 `xcodegen generate` 產生 `.xcodeproj`（不進版控）。
- [ ] 開啟 Capabilities（於 `project.yml` 宣告）：iCloud（CloudKit）、Push（背景同步）、In-App Purchase。
- [ ] 建立 iCloud container（私有資料庫）。
- [ ] 導入 Google AdMob SDK（SPM，於 `project.yml` 宣告 package）。
- [ ] 專案目錄結構依 MVVMC 分層建立。

## Phase 1 — 資料層（`02-architecture` §1–§3 §5）

- [ ] `FoodItemEntity` `@Model`：CloudKit-safe（全欄位有預設值、無 `.unique`）、`@Attribute(.externalStorage) imageData`。
- [ ] Domain：`FoodItem`、`RecordStatus`(active/consumed/wasted)、`ExpiryStatus`(fresh/nearExpiry/expired)。
- [ ] `FoodItemEntity.toDomain()`（含 `statusRaw` → `RecordStatus`）。
- [ ] `ExpiryStatus` 計算（daysUntil 演算法，§5）+ 單元測試（邊界 −1 / 0 / 3 / 4）。
- [ ] 圖片壓縮工具：JPEG 0.7、長邊 1024px → `Data`（§3）。
- [ ] `SwiftDataManager`（@MainActor）：
  - [ ] 依 UserDefaults「iCloud 開關」建立掛/不掛 `cloudKitDatabase` 的 ModelContainer（同一 store URL）。
  - [ ] CRUD：`create` / `update` / `delete`(hard) / `markConsumed` / `markWasted` / `fetchActiveFoods`（排序：expiryDate↑, createdAt↑）。
  - [ ] 邊界只回傳 Domain，不外洩 `@Model`。
- [ ] Mock：`FoodItem.mock` / `.mocks`（`#if DEBUG`，`mvvmc-model` 規範）。

## Phase 2 — 導航基礎（`01-navigation` §7、`mvvmc-navigation` / `mvvmc-hostcontroller`）

- [ ] `AppRouter`（stateless）：push Form(add/edit)、present 快捷 date picker、開 SFSafariViewController、開系統設定。
- [ ] TabView 三分頁裝配（首頁 / 分析 / 設定），各含 NavigationStack。
- [ ] SceneDelegate 導航裝配。
- [ ] HostController 橋接（SwiftUI ↔ UIKit）依 skill。

## Phase 3 — 首頁（`03-screens/home.md`）

- [ ] `HomeViewModel`（@Observable @MainActor）：State + `doAction`（onAppear / tapAdd / tapRow / swipeConsume / delete 確認流 / extend / menu 動作）。
- [ ] `HomeView`：廣告 section（可隱藏）+ 清單 + FAB + 空狀態 hint。
- [ ] Row：縮圖 / 名稱 / 到期資訊 / 狀態顏色（不顯示購買日）。
- [ ] 滑動：leading=已使用、trailing=刪除（跳確認）；長按 context menu 完整 5 項。
- [ ] 延長效期：快捷 date picker → 存 → 重排通知。
- [ ] onAppear 重撈刷新。
- [ ] ViewModel 測試（`mvvmc-testing`：`doAction(.apiResponse...)` 注入）。

## Phase 4 — 食材 Form（`03-screens/form.md`）

- [ ] `FoodFormViewModel`：Mode(add/edit)、State（含 `isSaveEnabled`）、dirty 快照比對、`doAction`。
- [ ] `FoodFormView`：名稱 TextField、購買日 / 到期日 DatePicker（到期日下限=購買日）、圖片區塊。
- [ ] 圖片來源 action sheet：拍照 / 相簿 / 移除 / 取消 → 壓縮存 Data。
- [ ] 儲存驗證（名稱去空白非空 → Save 才可按）。
- [ ] 返回放棄確認（有變更才跳）。
- [ ] 儲存流程：首次成功儲存請求通知權限 → manager 寫入 → 排程/重排通知 → pop。
- [ ] ViewModel 測試。

## Phase 5 — 分析（`03-screens/analytics.md`）

- [ ] `AnalyticsViewModel`：三桶 State、onAppear 分桶。
- [ ] `AnalyticsView`：急→緩三 Section（空桶顯示 0）、唯讀 row。
- [ ] ViewModel 測試。

## Phase 6 — 設定（`03-screens/settings.md`）

- [ ] `SettingsViewModel`：State + `doAction`。
- [ ] Section 購買 / 同步與通知 / 關於。
- [ ] iCloud 開關 → 存偏好 + 「下次啟動生效」提示。
- [ ] 通知列：顯示狀態 + 導向系統設定。
- [ ] 隱私權政策：SFSafariViewController。
- [ ] 版本顯示。

## Phase 7 — 通知（`02-architecture` §8）

- [ ] 通知服務：情境式請求權限（首次儲存）。
- [ ] 排程：到期日 09:00、以食材 id 為 identifier、過去時間不排。
- [ ] 取消/重排：編輯延長 / 刪除 / 已使用 / 丟棄。
- [ ] 64 則上限策略：nearest-first。

## Phase 8 — IAP 移除廣告（`02-architecture` §7）

- [ ] StoreKit 2 產品設定（非消耗型）+ StoreKit config 檔（本地測試）。
- [ ] entitlement 查詢（`currentEntitlements`）+ `Transaction.updates` 監聽。
- [ ] 購買 / 還原流程 + 錯誤處理。
- [ ] 廣告顯示與否綁定 entitlement。

## Phase 9 — 廣告 + ATT（`Spec` Production §2、`01-navigation` §2）

- [ ] AdMob 首頁頂部單一 banner section（標「廣告」、明顯區隔）。
- [ ] ATT 同意流程；拒絕 → 非個人化廣告 fallback。
- [ ] 空清單仍顯示廣告 + hint（`01-navigation` §2）。

## Phase 10 — iCloud 同步驗證（`02-architecture` §6）

- [ ] 開/關同步重啟生效驗證（同一 store URL）。
- [ ] 關→開：既有本機資料自動上傳；圖片（externalStorage）同步驗證。
- [ ] 多裝置同 Apple ID 同步實測。
- [ ] **上架前將 CloudKit schema 從 Development 部署到 Production**（CloudKit Dashboard），否則正式版無法同步。
- [ ] 確認 `VersionedSchema` 接法就位（`02-architecture` §10），未來欄位只加不改。

## Phase 11 — 合規與韌性（`Spec` Production §3 §4 §5）

- [ ] 隱私權政策網頁（GitHub Pages / 靜態頁）+ 填入 App Store Connect URL。
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
