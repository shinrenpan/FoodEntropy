## Summary

在 App Store Connect 的兩個語系補填行銷 URL 為 `https://shinrenpan.github.io/FoodEntropy/`，使 AdMob 能推導出網域並驗證既已部署的 app-ads.txt。此欄位無法在已上架版本單獨修改，須隨下一次版本送審一併提交。

## Motivation

v1.0.0 上架至今，AdMob 後台的 app-ads.txt 始終顯示「找不到 app-ads.txt 檔案」。實際查證後，檔案本身完全正確：

```
$ curl -s -o /dev/null -w "%{http_code}" https://shinrenpan.github.io/app-ads.txt
200
$ curl -s https://shinrenpan.github.io/app-ads.txt
google.com, pub-9003896396180654, DIRECT, f08c47fec0942fa0
```

問題在上游：AdMob 爬蟲不從 app 取得任何資訊，而是從 App Store 商店資訊的**行銷 URL** 解析出 hostname，再到該網域根目錄尋找檔案。以 API 查詢確認兩個語系的該欄位皆為空：

```
loc en-US   | marketingUrl= None
loc zh-Hant | marketingUrl= None
```

商店頁面因此沒有「開發者網站」連結（`sellerUrl` 為 `None`），爬蟲推導不出要去哪個網域。後台的「app-ads.txt 網址」與「上次檢索時間」兩欄都是空的——那才是真正的訊號：不是去過但沒找到，是根本沒有可去之處。錯誤訊息把人導向檢查檔案，但檔案從頭到尾都是對的。

未驗證的實際代價是部分廣告需求方不出價，填充率與收益受損。

嘗試以 API 單獨補填被 Apple 擋下：

```
409 STATE_ERROR — Attribute 'marketingUrl' cannot be edited at this time
```

行銷 URL 綁定版本，`READY_FOR_SALE` 狀態下無法修改。這正是 `app-store-listing` 記錄的「欄位修正成本分野」——它只能隨新版本送審。

## Proposed Solution

在下一次版本送審時，於 App Store Connect 的 `en-US` 與 `zh-Hant` 兩個語系填入行銷 URL `https://shinrenpan.github.io/FoodEntropy/`，其 hostname `shinrenpan.github.io` 與 app-ads.txt 的託管網域一致。送審通過後給 AdMob 至多 24 小時完成檢索與驗證，再確認後台狀態。

## Non-Goals

- 不修改任何程式碼——本 change 無 Swift 變更。
- 不修改 app-ads.txt 檔案本身或其託管方式（檔案已正確部署，屬 `advertising` 範圍）。
- 不修改其他商店資訊欄位（描述、關鍵字、截圖等）；若下次送審同時要更新它們，屬該次送審的其他工作，不在本 change 內。
- 不新增或修改任何 capability spec——所需的規格已存在（見下）。
- 不處理 AdMob 帳戶層級的其他設定。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

（無）

本 change 不改動任何 capability spec。`app-store-listing` 的 requirement「The marketing URL is mandatory and its host must serve app-ads.txt」已完整描述所需狀態，其中一個 scenario 更明確涵蓋了目前的失敗態（「An empty marketing URL reports as a missing file」）。本 change 的工作是讓實際的商店資訊符合那條既有規格，而非改變規格本身。

## Impact

- Affected specs: （無變更）；符合 `app-store-listing`，解除 `advertising` 記錄的驗證阻塞
- Affected code:
  - New: （無）
  - Modified: （無）
  - Removed: （無）
  - Reference: `openspec/specs/app-store-listing/spec.md`, `openspec/specs/advertising/spec.md`
- 外部系統：App Store Connect（行銷 URL 欄位）、AdMob（app-ads.txt 驗證狀態）
- 相依：必須搭載一個新的 build 送審，無法單獨執行
