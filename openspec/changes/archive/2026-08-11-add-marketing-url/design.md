## Context

這是一個規範對象完全在 repo 之外的 change：要改的是 App Store Connect 上的一個欄位，程式碼一行都不動。它之所以需要走 SDD 流程而不是一張便條，是因為它有兩個容易踩錯的約束——填什麼值、以及什麼時候才填得進去。

## Goals / Non-Goals

**Goals:**
- 確定要填入的 URL，以及為何是這個值。
- 記錄送審綁定的約束與其對執行時機的影響。
- 記錄驗證方式與可接受的等待窗口。

**Non-Goals:**
- 不改程式碼、不改 app-ads.txt、不改其他商店欄位。
- 不改任何 capability spec。

## Decisions

### 填入 `https://shinrenpan.github.io/FoodEntropy/`，而非根網域

爬蟲只取 hostname，因此 `https://shinrenpan.github.io/`、`https://shinrenpan.github.io/FoodEntropy/` 與 `https://shinrenpan.github.io/FoodEntropy/privacy` 對驗證而言完全等價——三者的 hostname 都是 `shinrenpan.github.io`，都會讓爬蟲去抓 `https://shinrenpan.github.io/app-ads.txt`。

選擇專案頁而非根網域的理由與驗證無關，而是這個欄位在 App Store 上會顯示為「開發者網站」，使用者點進去應該看到這個 app 的介紹，而不是開發者的所有專案清單。確認該路徑可用：

```
https://shinrenpan.github.io/FoodEntropy/ → 200
```

考慮過的替代方案：填支援 URL 已在用的 `https://shinrenpan.github.io/FoodEntropy/privacy`——否決，隱私權政策頁作為「開發者網站」在語意上不對，且該 URL 已有自己的欄位歸屬。

### 必須隨新版本送審，不能單獨提交

行銷 URL 屬版本綁定欄位，已上架版本回 `409 STATE_ERROR`。因此本 change 的執行前提是「有一個新 build 要送審」——而 Apple 不允許同一個 build 綁定兩個版本，所以必須 bump build number 並重新上傳，即使程式碼零變動。

這使得執行時機有兩種選擇：其一，為此單獨送一次 metadata 版本（例如 v1.0.1）；其二，等 v1.1 有實際功能時一併帶上。前者讓 app-ads.txt 早幾週生效、早一點開始正常出價；後者省一次審核往返。此決定不在本 change 內固定，由執行當下的判斷決定——但無論選哪個，本 change 的內容不變。

### 兩個語系都要填

`en-US` 與 `zh-Hant` 各自有獨立的 `marketingUrl` 欄位。理由：商店資訊是逐語系的，只填其一會讓另一語系的商店頁面仍然沒有開發者網站連結；而爬蟲從哪個語系取值並無保證。兩個填同一個 URL 即可——該頁本身為中英雙語。

### 驗證分兩段，不能只看送審通過

送審通過只代表欄位已生效，不代表 AdMob 已重新檢索。官方文件說明變更後最多需要 24 小時被偵測。因此驗證要分兩段：先以 API 確認 `marketingUrl` 非空、商店頁面出現開發者網站連結；再等待並確認 AdMob 後台的「app-ads.txt 網址」欄位**由空轉為實際網址**、且狀態轉為已驗證。

第二段的關鍵指標是那個網址欄位而非狀態文字——狀態可能因其他原因顯示異常，但只要網址欄位有值，就代表爬蟲已經知道要去哪裡，鏈路的上游已經打通。

## Implementation Contract

**Behavior (observable):**
- App Store 頁面顯示「開發者網站」連結，指向 `https://shinrenpan.github.io/FoodEntropy/`。
- AdMob 後台的 app-ads.txt 項目顯示實際的檢索網址與檢索時間，狀態為已驗證。

**Interface / data shape:**
- App Store Connect：`appStoreVersionLocalizations` 的 `marketingUrl`，`en-US` 與 `zh-Hant` 皆設為 `https://shinrenpan.github.io/FoodEntropy/`。
- 不涉及任何程式碼介面。

**Acceptance criteria:**
- 以 ASC API 查詢兩個語系的 `marketingUrl`，皆為該 URL 且非空。
- `https://itunes.apple.com/lookup?id=6793926521` 回傳的 `sellerUrl` 非空。
- `curl -s -o /dev/null -w "%{http_code}" https://shinrenpan.github.io/app-ads.txt` 回傳 200（前提條件，執行前後皆應成立）。
- AdMob 後台的「app-ads.txt 網址」欄位非空。

**Scope boundaries:**
- In scope：填入行銷 URL、送審、驗證。
- Out of scope：程式碼變更、app-ads.txt 檔案與託管（`advertising`）、其他商店欄位、AdMob 帳戶其他設定。

## Risks / Trade-offs

- [必須搭一個新 build 送審] → 即使零程式碼變更也要 bump build、重新 archive 上傳，並承擔一次審核往返（通常 1–2 天）。若與 v1.1 一併送出可省下這次往返，代價是 app-ads.txt 繼續未驗證數週。
- [驗證有最長 24 小時的延遲] → 送審通過後無法立即確認成功，需要隔日再查。
- [送審引入非預期的退件風險] → 一次 metadata-only 送審理論上風險極低（無新功能、無新權限），但任何送審都可能觸發審核者對既有內容的重新檢視。
- [AdMob 可能仍需額外時間或有其他阻塞] → 本 change 只解除已知的上游阻塞；若補填後仍未驗證，需另行查證是否有 AdMob 帳戶層級的問題，那不在本 change 範圍。
