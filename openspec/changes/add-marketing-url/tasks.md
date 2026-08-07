## 1. 前置確認

- [ ] 1.1 確認 app-ads.txt 仍可公開存取且內容正確；驗證：`curl -s -o /dev/null -w "%{http_code}" https://shinrenpan.github.io/app-ads.txt` 回 200，且內容含 `pub-9003896396180654`。
- [ ] 1.2 確認要填入的頁面存在；驗證：`curl -s -o /dev/null -w "%{http_code}" -L https://shinrenpan.github.io/FoodEntropy/` 回 200。
- [ ] 1.3 確認目前 `marketingUrl` 仍為空（若已非空則本 change 已無必要）；驗證：以 ASC API 查詢 `appStoreVersionLocalizations`，`en-US` 與 `zh-Hant` 的 `marketingUrl` 皆為 `None`。

## 2. 送審

- [ ] 2.1 在 `project.yml` 將 `CURRENT_PROJECT_VERSION` 遞增（同一 build 不能綁兩個版本）；驗證：`grep CURRENT_PROJECT_VERSION project.yml` 顯示新值，且該值未曾上傳過。
- [ ] 2.2 重新產生專案並 archive；驗證：`xcodegen generate` 成功，archive 產物存在且版本號與 2.1 一致。
- [ ] 2.3 上傳至 App Store Connect 並等待處理完成；驗證：ASC 上該 build 狀態非 `PROCESSING`。
- [ ] 2.4 建立新版本並選取該 build；驗證：ASC API 查得新版本存在且已綁定 2.3 的 build。
- [ ] 2.5 於 `en-US` 與 `zh-Hant` 兩個語系填入 `https://shinrenpan.github.io/FoodEntropy/`；驗證：PATCH 回傳 200（非 `409 STATE_ERROR`），且查詢結果為該 URL。
- [ ] 2.6 送審並等待通過；驗證：版本狀態轉為 `READY_FOR_SALE`。

## 3. 驗證

- [ ] 3.1 確認商店頁面已出現開發者網站連結；驗證：`https://itunes.apple.com/lookup?id=6793926521` 回傳的 `sellerUrl` 非空且 hostname 為 `shinrenpan.github.io`。
- [ ] 3.2 等待至多 24 小時後確認 AdMob 已完成檢索；驗證：AdMob 後台該 app 的「app-ads.txt 網址」欄位由空轉為實際網址、「上次檢索時間」有值，狀態為已驗證。
- [ ] 3.3 若 3.2 逾 24 小時仍未通過，記錄後台顯示的實際欄位值以判斷阻塞點；驗證：確認網址欄位是否已有值——有值代表爬蟲已知去向、問題在下游；仍為空代表行銷 URL 未生效，回頭檢查 3.1。
