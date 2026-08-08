## Summary

把本 app 的網頁（落地頁與隱私權政策）從 `FoodEntropy/docs/` 移到 `shinrenpan.github.io/static/FoodEntropy/`，與 HerbMeet 既有的做法一致，並關閉 FoodEntropy repo 的 GitHub Project Pages。URL 完全不變。

## Motivation

目前兩個 app 的網頁放在不同地方，規則不一致：

| app | 檔案位置 | Pages 來源 |
|---|---|---|
| HerbMeet | `shinrenpan.github.io/static/herbmeet/` | User Pages（集中） |
| **FoodEntropy** | **`FoodEntropy/docs/`** | **Project Pages（分散）** |

這個不一致不是刻意的設計。追查 git 歷史，`docs/` 由 2026-07-23 的 commit `4797553` 引入，當時的目的是「取得一個可填入 App Store 的隱私權政策 URL」——commit message 記錄了做什麼與為什麼需要那個頁面，但**沒有提到跨 repo 的選擇，也沒有提及 `shinrenpan.github.io` 已有 `static/herbmeet/` 這套模式**。換言之，當初不是在兩種做法之間做了決定，而是取了最短路徑，於是不一致就固定下來。

它躲過了兩道檢查：commit message 看不出這是個決定；而 `app-store-listing` 與 `advertising` 的 spec 雖然都提到那個網域，卻沒有記錄檔案位於哪個 repo——補 baseline 時只讀 spec 與程式碼，不會發現另一個 repo 有不同做法。

集中的實際好處是**不必記兩套規則**（本 change 的起因正是「為什麼 FoodEntropy 的頁面在這裡」這個疑問），且兩個 app 的頁面可共用 Hugo 的樣式，呈現一致的作者形象。

## Proposed Solution

分兩階段，避免任何服務中斷：

**階段一（可立即執行，零風險）**
複製 `docs/` 的內容到 `shinrenpan.github.io/static/FoodEntropy/`（保持目錄名大小寫）並部署。此時 `/FoodEntropy/` 仍由 Project Pages 服務，線上行為完全不變，新檔案處於「就位但未生效」狀態。

**階段二（1.1.0 上架後執行）**
關閉 FoodEntropy repo 的 GitHub Pages，路由即交由 User Pages 承接（檔案已就位，無空窗）；確認線上 URL 正常後，移除 `docs/`。

順序不可顛倒：**先部署新位置、再關閉舊來源**。若先關閉 Project Pages，`/FoodEntropy/` 會在 Hugo 部署完成前回傳 404——而隱私權政策 URL 無法存取是明確的 App Store 退件理由。

## Non-Goals

- 不改變任何 URL。目錄名維持 `FoodEntropy`（大寫 F、E）——GitHub Pages 路徑**大小寫敏感**（`/HerbMeet/` 為 404，僅 `/herbmeet/` 有效）。URL 一旦變動，App Store Connect 的隱私權政策欄位、行銷 URL、app 內的常數、以及**已上架的 v1.0.0** 全都需要更新。
- 不改動網頁內容（文案、樣式、雙語）；本 change 只搬位置。
- 不動 `app-ads.txt`。它必須留在網域根目錄（`shinrenpan.github.io` repo），因為廣告爬蟲只取 hostname 並抓 `/app-ads.txt`——放在子路徑無效。
- 不統一 HerbMeet 與本 app 的頁面樣式（可行但屬另一件事）。

## Capabilities

### Modified Capabilities

- `app-store-listing`：補記隱私權政策與行銷 URL 所指頁面的託管位置，以及 GitHub Pages 的跨 repo 路由機制——同一 hostname 下，`/<repo>/` 由該 repo 的 Project Pages 服務，其餘由 User Pages 服務。這解釋了為何 `app-ads.txt` 與 app 頁面必須分屬不同 repo。

### New Capabilities

（無）

## Impact

- Affected specs: `app-store-listing`
- Affected code:
  - Removed: `docs/`（階段二）
  - 外部 repo: `shinrenpan.github.io/static/FoodEntropy/`（階段一新增）
- 外部設定：關閉 FoodEntropy repo 的 GitHub Pages（階段二）
- 前置條件：**1.1.0 上架**（`READY_FOR_SALE`）後才執行階段二
