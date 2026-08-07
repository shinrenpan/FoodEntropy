# Capability map

不是 OpenSpec/Spectra 的機制——spec 檔之間沒有正式的相依連結。這是一份手動維護的索引，讓讀者不必打開每一份 spec 才能看出它們怎麼串起來。每份 `design.md` 也會用 backtick 內嵌標註相依（依 `openspec/config.yaml` 的 `rules.design`），本檔只是彙總視圖。

新增／移除 capability，或改變彼此的引用關係時，更新這份檔案。

## 狀態

v1.0.0 早於 Spectra 導入，其 capability 已全數以 `baseline-*` change 回溯補回（見 `openspec/changes/archive/`）。頂層 `specs/` 為 pre-Spectra 設計文件，已完成其素材任務且部分內容與實作脫節（例如 `03-screens/settings.md` 仍描述 v1 的 IAP stub），**不再是任何決策的依據**，可移除。

## Foundation

- **`app-shell`** ✅ — UIKit 生命週期進入點、SceneDelegate composition root、store 三層降級、兩 Tab root、平台外框、XcodeGen 與 MVVMC 資料夾慣例。其他所有 capability 都跑在它之上。
- **`navigation`** ✅ — push-based `AppRouter`、轉場記憶與 `back()` 分流、互動手勢條件、`onRoute` 模式、集中式 `Deeplink`。跑在 `app-shell` 裝配的 tab bar 與各 Tab 的 navigation stack 上。

## Domain rules（跨畫面共用——不併入任何單一畫面）

- **`food-item`** ✅ — Domain model、`RecordStatus`／`ExpiryStatus` 雙軸狀態、四種 row 出口（延長／已使用／丟棄／刪除）。被所有畫面消費。
- **`persistence`** ✅ — SwiftData `@Model` 的 CloudKit-safe 約束、`SwiftDataManager` 與 `toDomain()` 轉換、`VersionedSchema`、圖片 externalStorage 與壓縮。`app-shell` 負責建立它，本 capability 定義它的契約。
- **`icloud-sync`** ✅ — opt-in、預設關、下次啟動生效。由 `settings-ui` 操作，影響 `persistence` 的容器選擇。
- **`notification`** ✅ — 到期當天 09:00、一項一則、首次儲存請求權限、前景對帳排程。由 `food-form-ui` 觸發排程、`app-shell` 在進前景時觸發對帳。
- **`iap-remove-ads`** ✅ — `StoreManager`、購買與還原、entitlement 單一真相來源。由 `settings-ui` 操作，`advertising` 讀其結果。
- **`advertising`** ✅ — AdMob 初始化、廣告單元設定、無 fill 收合、app-ads.txt。由 `home-ui` 呈現，受 `iap-remove-ads` 的 entitlement 抑制。

## Screens（UI capabilities）

- **`home-ui`** ✅ — 現況甜甜圈 + 浪費統計 + 分桶清單（原分析頁已於 v1.0.0 併入），透過 `navigation` 進出 `food-form-ui`。
- **`food-form-ui`** ✅ — 新增／編輯共用 Form、照片選取與大圖預覽。
- **`settings-ui`** ✅ — 承載 `iap-remove-ads`、`icloud-sync`、`notification` 權限引導、隱私權政策、版本。

## Cross-cutting

- **`localization`** ✅ — String Catalog（zh-Hant base + en）、日期與數字的系統格式化、「哪些刻意不翻譯」的界線。橫跨全部 UI capability。
- **`app-store-listing`** ✅ — App Store 線上 metadata 與 app 實際功能的一致性規範。唯一規範對象不在 repo 內的 capability，線上實際值以 App Store Connect API 查詢為準。須涵蓋行銷 URL 必填且其 hostname 需與 `advertising` 的 app-ads.txt 託管網域一致——v1.0.0 因此欄留空導致 AdMob 無法驗證 app-ads.txt。
