## 1. 階段一：新位置就位（零風險，可立即執行）

- [x] 1.1 複製 `docs/index.html` 與 `docs/privacy/index.html` 至 `shinrenpan.github.io/static/FoodEntropy/`，保持目錄名大小寫；驗證：兩檔的 SHA-256 與來源一致，且目錄名為 `FoodEntropy`（非小寫）。
- [ ] 1.2 於 `shinrenpan.github.io` commit 並 push，等待部署完成；驗證：該 repo 的 Pages 部署成功，且 `https://shinrenpan.github.io/FoodEntropy/` 仍回傳 200（此時仍由 Project Pages 服務，內容不變——確認線上未受影響）。

## 2. 階段二：切換與清理（**1.1.0 上架後**才執行）

- [ ] 2.1 確認 1.1.0 已 `READY_FOR_SALE`；驗證：以 ASC API 查詢版本狀態。
- [ ] 2.2 關閉 FoodEntropy repo 的 GitHub Pages；驗證：`gh api repos/shinrenpan/FoodEntropy/pages` 回傳 404。
- [ ] 2.3 確認路由已交由 User Pages 承接；驗證：`https://shinrenpan.github.io/FoodEntropy/` 與 `.../privacy` 皆回傳 200，且內容與階段一部署的檔案一致（可比對 `<title>`）。**若出現 404，先重新啟用 Project Pages 復原，再排查 Hugo 是否正確發布 `static/FoodEntropy/`。**
- [ ] 2.4 確認 App Store 上的隱私權政策連結可用；驗證：以 ASC API 取得 1.1.0 的隱私權政策 URL 並 curl，回傳 200。
- [ ] 2.5 移除本 repo 的 `docs/`；驗證：`git rm -r docs/` 後，`grep -rn "docs/" --include="*.md" .` 無殘留引用（README、CLAUDE.md）。
- [x] 2.6 撰寫 `app-store-listing` 的 delta spec — 實現「Every app's pages live in the developer site repository」與「The ad-network file and the app's own pages are hosted separately by necessity」；驗證：delta 已隨本 change 提供，涵蓋託管位置慣例、路徑大小寫敏感、來源優先順序，以及 app-ads.txt 必須位於網域根目錄的理由。

## 3. 驗收

- [ ] 3.1 兩個 app 的頁面位置一致 — 對應「Every app's pages live in the developer site repository」；驗證：`shinrenpan.github.io/static/` 下同時存在 `herbmeet/` 與 `FoodEntropy/`，且無任何 app 的頁面留在自己的 repo。
- [ ] 3.2 `app-ads.txt` 未受影響 — 對應「The ad-network file and the app's own pages are hosted separately by necessity」；驗證：`curl -s https://shinrenpan.github.io/app-ads.txt` 回傳 200 且內容含本 app 的 publisher 條目。
