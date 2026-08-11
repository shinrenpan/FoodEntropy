## 1. 前置確認

- [x] 1.1 確認 app-ads.txt 仍可公開存取且內容正確；驗證：**已完成**——回傳 200，`content-type: text/plain; charset=utf-8`，內容為 `google.com, pub-9003896396180654, DIRECT, f08c47fec0942fa0`（59 bytes，無 BOM、結尾有 LF）。
- [x] 1.2 確認要填入的頁面存在；驗證：**已完成**——`https://shinrenpan.github.io/FoodEntropy/` 回傳 200。
- [x] 1.3 確認目前 `marketingUrl` 仍為空（若已非空則本 change 已無必要）；驗證：**已完成**——執行當下 `en-US` 與 `zh-Hant` 皆為 `None`，本 change 成立。

## 2. 送審

- [x] 2.1 在 `project.yml` 將 `CURRENT_PROJECT_VERSION` 遞增（同一 build 不能綁兩個版本）；驗證：**已完成**——隨 v1.1.0 一併處理。
- [x] 2.2 重新產生專案並 archive；驗證：**已完成**——Release archive 產出成功。匯出階段曾因 Homebrew 版 rsync 的參數差異失敗，改用系統 rsync 後通過。
- [x] 2.3 上傳至 App Store Connect 並等待處理完成；驗證：**已完成**——build 通過處理與驗證。
- [x] 2.4 建立新版本並選取該 build；驗證：**已完成**——1.1.0 已綁定該 build。
- [x] 2.5 於 `en-US` 與 `zh-Hant` 兩個語系填入 `https://shinrenpan.github.io/FoodEntropy/`；驗證：**已完成**——兩語系查詢結果皆為該 URL（未再遇到 `409 STATE_ERROR`，因為是在新版本上編輯）。
- [x] 2.6 送審並等待通過；驗證：**已完成**——2026-08-08 21:03 送審，23:31 通過，手動發佈後轉為 `READY_FOR_SALE`。

## 3. 驗證

- [x] 3.1 確認商店頁面已出現開發者網站連結；驗證：**已完成**——`sellerUrl` 為 `https://shinrenpan.github.io/FoodEntropy/`，hostname 正確。注意：**不帶 `country` 參數的 lookup 查詢落在預設 storefront，其快取更新較慢**，發佈後數小時仍回傳舊版與 `None`；帶 `country=tw`／`us`／`jp` 查詢則已是新值。判定應以指定 storefront 為準。
- [x] 3.2 確認 AdMob 已完成檢索；驗證：**已完成**——2026-08-11 通過，AdMob 顯示「『食熵』(iOS 版) 已順利完成驗證」。**但並非等待所得**：`sellerUrl` 生效後被動等了約 64 小時，後台三個欄位始終全空、狀態停在「找不到 app-ads.txt 檔案」。實際解法見 3.3。
- [x] 3.3 逾時後的排查與觸發；驗證：**已完成**——原判準（「網址欄位仍為空 = 行銷 URL 未生效，回頭檢查 3.1」）**是錯的**，實際存在第三種情況：URL 早已生效，但 AdMob 未重新讀取商店項目。正確處置依序為：
  - **(a) 先判讀欄位語意**——官方文件載明：若找不到檔案，欄位會**顯示商店項目關聯的網域**；若**完全空白**，代表商店項目上沒有關聯網域，或 AdMob 尚未偵測到該商店項目的近期變更。因此「全空」指向商店項目未被重讀，而非檔案有問題，此時檢查檔案是走錯方向。
  - **(b) 佐證資料在 Apple 端是齊的**——直接抓 `apps.apple.com` 商店頁 HTML，確認含 `"text":"Developer Website"` 且 `actionDetails.type` 為 `developer`（tw 與 us 皆有）。齊備即代表本專案可控範圍全部正確，問題在 AdMob 側。
  - **(c) 主動觸發**——於 AdMob 應用程式清單執行「驗證應用程式 → 檢查更新」。**第一次會以同樣訊息失敗（回報快取狀態並發出重讀請求），第二次才取得重讀結果並通過。單次失敗不代表此動作無效。**
  - **(d) 仍失敗才開支援單**——附上 (b) 的 HTML 佐證。本次未走到這一步。
- [x] 3.4 確認同意聲明管理平台（CMP）義務是否適用；驗證：**已完成**——驗證通過後 AdMob 提示須設定 Google 認證的 CMP 才能於歐洲經濟區、英國、瑞士放送個人化廣告。查 `appAvailabilityV2` 的 `territoryAvailabilities`：175 個地區中實際可販售 132 個，**EEA 30 國、GBR、CHE 命中數皆為 0**，故義務不適用，無需設定 CMP。**遺留風險**：`availableInNewTerritories` 為 `True`，Apple 日後新增地區會自動上架，屆時可能無聲觸發此義務。
- [x] 3.5 記錄後續等待項；驗證：**已完成**——驗證通過後仍有「廣告放送資格審查」，AdMob 表示通常 2–3 天、期間廣告放送受限。此即先前觀察到「28 天內 154 次請求但預估收益 US$0.00」的成因：整合正常，限制屬行政性質，審查完成後由 AdMob 以電子郵件通知。
