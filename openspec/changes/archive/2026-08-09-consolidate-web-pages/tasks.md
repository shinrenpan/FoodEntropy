## 1. 階段一：新位置就位（零風險，可立即執行）

- [x] 1.1 複製 `docs/index.html` 與 `docs/privacy/index.html` 至 `shinrenpan.github.io/static/FoodEntropy/`，保持目錄名大小寫；驗證：兩檔的 SHA-256 與來源一致，且目錄名為 `FoodEntropy`（非小寫）。
- [x] 1.2 於 `shinrenpan.github.io` commit 並 push，等待部署完成；驗證：**已完成**——commit `b431aef`（rebase 於既有的 app-ads.txt 三個 commit 之上，無交集），Pages build 狀態 `built`；線上 `/FoodEntropy/`、`/FoodEntropy/privacy`、`/app-ads.txt`、`/herbmeet/` 皆回傳 200，線上行為未受影響。

## 2. 階段二：切換與清理（**1.1.0 上架後**才執行）

- [x] 2.1 確認 1.1.0 已 `READY_FOR_SALE`；驗證：**已完成**——2026-08-08 23:31 通過審查（`PENDING_DEVELOPER_RELEASE`），手動發佈後 ASC API 查得 `appStoreState: READY_FOR_SALE`。
- [x] 2.2 關閉 FoodEntropy repo 的 GitHub Pages；驗證：**已完成**——刪除前記錄的來源為 `branch: main, path: /docs`（回滾用），`gh api repos/shinrenpan/FoodEntropy/pages` 現回傳 404。
- [x] 2.3 確認路由已交由 User Pages 承接；驗證：**已完成**——`/FoodEntropy/` 與 `/FoodEntropy/privacy` 皆回傳 200，`<title>` 與本地 `docs/` 相同（`食熵 FoodEntropy`、`隱私權政策 · Privacy Policy — 食熵 FoodEntropy`），未出現 404，無需回滾。**若出現 404，先重新啟用 Project Pages 復原，再排查 Hugo 是否正確發布 `static/FoodEntropy/`。**
- [x] 2.4 確認 App Store 上的隱私權政策連結可用；驗證：**已完成**——ASC API 查得 `appInfoLocalizations` 的 `privacyPolicyUrl` 為 `https://shinrenpan.github.io/FoodEntropy/privacy/`（zh-Hant 與 en-US 一致），curl 回傳 200；同時驗證 `marketingUrl`（`/FoodEntropy/`）與 `supportUrl`（`/FoodEntropy/privacy`）亦為 200。
- [x] 2.5a 刪除本 repo 的 `github-pages` environment 與部署記錄（於 2.2 關閉 Pages 之後）；驗證：**已完成**——environment `total_count` 為 0；刪除 environment 不連帶清除部署記錄，殘留的 35 筆 deployment 逐筆先 POST `state: inactive` 再 DELETE（GitHub 不允許刪除 `active` 狀態的 deployment），現 `deployments` 為 `[]`。此 environment 建於 2026-07-23，與 `docs/` 同日產生，是啟用 Project Pages 的副產物。
- [x] 2.5 移除本 repo 的 `docs/`；驗證：**已完成**——刪除前先比對兩檔的 SHA-256 與線上版本一致，確認新位置已完整承接內容後才 `git rm -r docs/`。殘留引用檢查：README 與 CLAUDE.md 皆無引用；grep 命中的 `.claude/skills/spectra-*/SKILL.md` 為 Spectra 模板自身的 `docs/specs/` 路徑，與本專案的 `docs/` 無關，本 change 自己的文件則應保留。
- [x] 2.6 撰寫 `app-store-listing` 的 delta spec — 實現「Every app's pages live in the developer site repository」與「The ad-network file and the app's own pages are hosted separately by necessity」；驗證：delta 已隨本 change 提供，涵蓋託管位置慣例、路徑大小寫敏感、來源優先順序，以及 app-ads.txt 必須位於網域根目錄的理由。

## 3. 驗收

- [x] 3.1 兩個 app 的頁面位置一致 — 對應「Every app's pages live in the developer site repository」；驗證：**已完成**——`shinrenpan.github.io/static/` 下同時存在 `herbmeet/` 與 `FoodEntropy/`，且 FoodEntropy repo 的 `docs/` 已於 2.5 移除，無任何 app 的頁面留在自己的 repo。
- [x] 3.2 `app-ads.txt` 未受影響 — 對應「The ad-network file and the app's own pages are hosted separately by necessity」；驗證：**已完成**——`curl -s https://shinrenpan.github.io/app-ads.txt` 回傳 200，內容為 `google.com, pub-9003896396180654, DIRECT, f08c47fec0942fa0`。
