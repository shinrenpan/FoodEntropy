## 1. Baseline 文件化

- [x] 1.1 從 AdMob 的 app-ads.txt 驗證機制與 v1.0.0 的實際失敗態寫出 requirement「The marketing URL is mandatory and its host must serve app-ads.txt」；驗證：以 ASC API 查詢 `appStoreVersionLocalizations`，`en-US` 與 `zh-Hant` 的 `marketingUrl` 皆為 `None`；`https://itunes.apple.com/lookup?id=6793926521` 的 `sellerUrl` 為 `None`（商店頁面無開發者網站連結）；AdMob 後台顯示「找不到 app-ads.txt 檔案」且檢索網址與上次檢索時間皆為空；同時 `curl https://shinrenpan.github.io/app-ads.txt` 回 HTTP 200 且內容含 `pub-9003896396180654`——證實檔案無誤、缺的是行銷 URL。
- [x] 1.2 從 `SettingsViewModel.privacyPolicyURL` 與 ASC 上的隱私權政策設定寫出 requirement「The listing's privacy policy is the same page the app links to」；驗證：程式碼常數為 `https://shinrenpan.github.io/FoodEntropy/privacy`，與填入 App Store Connect 的同一個。
- [x] 1.3 從一般審核要求與本專案 roadmap 的未實作項目寫出 requirement「Store copy claims nothing the shipped build cannot do」；驗證：規格明列描述／宣傳文字／關鍵字／截圖四類欄位皆受此約束，並點名 roadmap 項目在實作前不得出現。
- [x] 1.4 從 `02-architecture` §9 的廣告策略與 AdMob 的資料收集行為寫出 requirement「Privacy labels cover what bundled third-party SDKs collect」；驗證：app 自身不收集使用者資料（資料留於裝置與使用者 iCloud，見 `persistence` 與 `icloud-sync`），但 AdMob 收集裝置識別碼用於第三方廣告，隱私標籤須涵蓋該項。
- [x] 1.5 從 `00-constitution` 的發行區域決定與 `advertising` 的 UMP 取捨寫出 requirement「Territory exclusions are compliance decisions with prerequisites」；驗證：憲章載明排除歐盟以避開 GDPR／DSA 負擔，且 `advertising` 記錄「排除歐盟後 v1.0.0 不接 UMP」——兩者互為前提。
- [x] 1.6 從補填行銷 URL 的實測結果寫出 requirement「Fields are chosen with their correction cost in mind」；驗證：對 `READY_FOR_SALE` 版本 PATCH `marketingUrl` 回傳 `409 STATE_ERROR — Attribute 'marketingUrl' cannot be edited at this time`，證實該欄位綁定版本；支援 URL 於同一版本上為已填且可維護狀態。

## 2. 收尾

- [x] 2.1 執行 `spectra validate baseline-app-store-listing`；驗證：指令回傳成功、無 error。
- [x] 2.2 archive 後補上 `openspec/specs/app-store-listing/spec.md` 的 `## Purpose` 段；驗證：`grep -c "TBD" openspec/specs/app-store-listing/spec.md` 為 0。
- [x] 2.3 更新 `openspec/specs/README.md`，將 Cross-cutting 兩個 capability 標為已補回並移除「狀態」段的過渡說明；驗證：檔案內無殘留「⬜ 待補」。
- [x] 2.4 ~~未結項目：補填行銷 URL~~ → **已轉為獨立 change `add-marketing-url` 追蹤**。baseline 的職責是記錄 v1.0.0 現況（proposal 明載「無行為變更」），不該夾帶未來要執行的動作；archive 代表完成，未勾的 task 留在此處既不會被 `spectra list` 看見，也不會有人執行。規格層面無需變動——`app-store-listing` 的 requirement「The marketing URL is mandatory and its host must serve app-ads.txt」已完整描述所需狀態，其中一個 scenario 正是目前的失敗態。
