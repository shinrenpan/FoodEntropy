## Summary

補回 v1.0.0 的 App Store 商店資訊 baseline：行銷 URL 與 app-ads.txt 託管網域的一致性要求、隱私權政策 URL 與 app 內連結的同一性、文案不得承諾 build 沒有的功能、隱私標籤須涵蓋廣告 SDK 的收集項，以及「哪些欄位可隨時修正、哪些必須綁版本送審」的分野。無行為變更。

## Motivation

這是唯一一個規範對象不在 repo 裡的 capability——它管的是 App Store Connect 上的欄位，而那些欄位會直接影響 app 的實際行為與收益。

促成它的是一個實際發生的問題：**v1.0.0 的行銷 URL 留空，導致 AdMob 始終無法驗證 app-ads.txt。** AdMob 爬蟲不是從 app 得知該去哪裡找檔案，而是從 App Store 商店資訊的「行銷 URL」取出 hostname，再到該網域根目錄尋找。檔案本身部署正確、可公開存取、內容無誤，但爬蟲連要去哪個網域都推導不出來，後台顯示的是「找不到 app-ads.txt 檔案」且檢索網址為空——錯誤訊息完全指向錯誤的方向，容易讓人反覆檢查檔案而不是商店欄位。

第二件事是修正成本的分野。嘗試補填時得到的回應是：

```
409 STATE_ERROR — Attribute 'marketingUrl' cannot be edited at this time
```

已上架版本的行銷 URL 無法單獨修改，必須綁在新版本一起送審；而支援 URL 這類欄位則可隨時更新。這個分野決定了「哪些內容適合放在會漂移的欄位」——放錯地方的代價是要為了一行字送一次審。

## Proposed Solution

從實際的 App Store Connect 現況（以 API 查詢為準）、`Sources/Features/Settings/SettingsViewModel.swift` 的隱私權政策 URL、`specs/00-constitution.md` 的發行區域決定與 `specs/02-architecture.md` §9 的廣告策略，寫出 `app-store-listing` capability spec，涵蓋：行銷 URL 的必填與網域一致性、隱私權政策 URL 的同一性、文案與實作的一致性、隱私標籤涵蓋廣告 SDK、發行區域的合規前提，以及可即時修正與需送審欄位的分野。

## Non-Goals

- 無行為變更，本次不修改任何 App Store Connect 欄位。
- 不涵蓋 app-ads.txt 檔案本身的內容與託管，那屬 `advertising`；本 capability 規範的是指向它的那個欄位。
- 不涵蓋 IAP 商品在 App Store Connect 上的設定與審核附註。
- 不在 repo 內保留線上實際值的抄本——線上狀態以 App Store Connect API 查詢為準，抄本必然漂移。
- 不涵蓋截圖與預覽影片的製作流程。

## Capabilities

### New Capabilities

- `app-store-listing`：行銷 URL 與 app-ads.txt 網域的一致性、隱私權政策 URL 同一性、文案與實作一致性、隱私標籤涵蓋範圍、發行區域合規前提、欄位修正成本分野。

### Modified Capabilities

（無）

## Impact

- Affected specs: new `app-store-listing`
- Affected code:
  - New: （無 —— 規範對象為 App Store Connect 上的欄位）
  - Modified: （無）
  - Removed: （無）
  - Reference: `Sources/Features/Settings/SettingsViewModel.swift`（隱私權政策 URL）、`specs/00-constitution.md`（發行區域）、`specs/02-architecture.md`（廣告與隱私策略）
