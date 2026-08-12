## 1. 寫入 spec

- [x] 1.1 於 `app-store-listing` 新增三條 requirement，各自涵蓋失敗徵兆與處置 — 對應「The export toolchain resolves to the system copy utility」「Changing an identifier's capabilities invalidates its distribution profile」「Demonstration data is regenerated immediately before capturing screenshots」；驗證：**已完成**——三條皆以「失敗時看起來像什麼」開場，因為這三個問題的表象與成因無關（「Copy failed」不含 rsync 字樣、實機成功不代表 distribution 可用、資料過期不會報錯只會靜默改變畫面）。

## 2. 驗證記錄與現實一致

- [x] 2.1 確認 rsync 條目所述的環境問題可重現且解法有效；驗證：`which -a rsync` 顯示 Homebrew 版（3.4.2）先於系統版（openrsync），且 1.2.0 上傳時將前者暫時移出 PATH 後 export 即成功——此為第二次遭遇（1.1.0 亦然），故列為 pre-upload 例行檢查而非個案。
- [x] 2.2 確認 distribution profile 條目所述情形與本次一致；驗證：`com.shinrenpan.FoodEntropy` 的 distribution profile 不含 App Groups（該 capability 於 1.2.0 開發期間才加入），`com.shinrenpan.FoodEntropy.Widget` 則無任何 distribution profile；以 API key 加自動更新選項執行 export 回報 `Cloud signing permission error`，改由 Xcode GUI 執行 distribute 後成功產生並上傳。
- [x] 2.3 確認示範資料條目所述的衰減行為；驗證：8 月 8 日灌入的資料於 8 月 12 日截圖時，五筆 active 中四筆已過期，Widget 呈現接近全紅且金額行未渲染；清空 store 後重灌，分布回復為過期 1、近期 3、期限內 1，金額行顯示「至少 $125 即將到期」。

## 3. 收尾

- [x] 3.1 確認本 change 未動任何原始碼或設定檔；驗證：**已完成**——git 變更僅有 `openspec/changes/add-submission-preflight/`，`Sources/`、`Tests/`、`project.yml` 皆無異動。
