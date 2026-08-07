## Context

廣告是這個 app 唯一的收益來源，也是唯一的第三方相依（Google Mobile Ads，classic SDK——iOS 尚無 Next-Gen 版本）。整層只有一個廣告位：首頁清單頂端的 320x50 banner。

設計上的所有取捨都圍繞同一個目標——**用最小的隱私足跡換取可接受的收益**：非個人化請求、不碰 IDFA、不跳 ATT、排除歐盟發行。代價是單價較低，但對低流量的工具型 app 而言，差異有限，換來的是最乾淨的隱私標籤與最少的合規摩擦。

## Goals / Non-Goals

**Goals:**
- 記錄「非個人化 + 不跳 ATT」的合規理由，避免被誤當成漏做而補上。
- 記錄開發／正式廣告單元編譯期分流的必要性。
- 記錄版位的三種載入狀態與收合規則。
- 記錄 app-ads.txt 的驗證鏈與其在 repo 之外的那一環。

**Non-Goals:**
- 無行為變更。
- 不涵蓋 `iap-remove-ads` 的購買流程、`home-ui` 的整體版面、`app-store-listing` 的欄位規範。

## Decisions

### 非個人化廣告，且刻意不請求 ATT

每個請求都帶 `npa=1` 的 extras，不存取 IDFA，也不呼叫 ATT。理由：ATT 只在「要追蹤」時才必要——而追蹤的定義正是存取 IDFA 做跨 App 的個人化。非個人化請求不碰 IDFA，因此不在 ATT 的適用範圍內；主動彈出一個無意義的權限請求，反而可能依 Apple Guideline 5.1.2 被判定為不當的權限索取而退件。同時，不跳 ATT 也意味著 `Info.plist` 不需要 `NSUserTrackingUsageDescription`。考慮過的替代方案：接受個人化廣告以提高單價——否決，那需要 ATT 彈窗、更複雜的隱私標籤，且在使用者拒絕（多數情況）時仍會退回非個人化，收益提升有限。

### 排除歐盟發行，因此不接 UMP 同意流程

GoogleUserMessagingPlatform 是 AdMob 的 transitive 相依，但 v1.0.0 不主動接入同意彈窗。理由：發行區域排除歐盟後，GDPR/DSA 的同意管理需求降到最低。這是一個發行策略與技術負擔的綁定決定——若未來要進入歐盟市場，UMP 接入是必要的前置工作，不能只改發行區域。

### 開發與正式廣告單元以編譯條件分流

`homeBannerUnitID` 在 DEBUG 回傳 Google 官方測試單元、Release 回傳正式單元。理由：以自己的正式廣告單元進行開發測試屬於無效流量，違反 AdMob 政策，最嚴重的後果是帳號被停用而失去全部收益。這個風險的特性是**靜默累積**——開發期間不會有任何警告，直到帳號被停。編譯期分流讓它不可能因為忘記切換而發生。App ID（`Info.plist` 的 `GADApplicationIdentifier`）則兩環境共用，差異只在廣告單元。

### 版位有三種狀態，只有失敗才收合

版位以載入中 / 已載入 / 失敗三態管理高度：載入中與已載入皆保留 50pt，只有失敗（含無 fill）收合為 0。理由：banner 需要非零的版位才能完成載入，若一開始就是 0 高度會讓廣告永遠載不出來。反過來，確定無 fill 之後保留空白版位只會在畫面頂端留下一塊無意義的空隙——收合為 0 讓「沒有廣告」在視覺上完全不存在，而不是一個空框。收合同時包含背景色與內距，避免殘留一條細線。

### 版位自帶不透明背景

版位背景使用不透明的系統群組背景色。理由：廣告釘在清單頂端（`safeAreaInset`），清單內容會從它下方捲過；沒有不透明底色時，捲動的內容會從半透明區域穿透顯示，與廣告重疊。

### 「廣告」標示只在載入成功後顯示

右上角的「廣告」文字僅在 `loaded` 狀態出現。理由：這個標示的用途是讓使用者能區分廣告與 app 自身內容——在還沒有廣告可看時顯示它，反而是在標示一塊空白。

### 由呼叫端依 entitlement 決定是否放入版位，而非由版位自行隱藏

`AdSlotView` 不知道 IAP 的存在；首頁依 `state.adsRemoved` 決定要不要把它放進畫面。理由：讓版位只負責「顯示一個 banner 並處理載入結果」這一件事，付費狀態的判斷留在有 `StoreManager` 可讀的 ViewModel 層。已購買的使用者連 `AdSlotView` 都不會被建立，因此不會發出任何廣告請求——這比「建立了但隱藏」更徹底，也避免了無謂的網路請求與曝光計數。

### rootViewController 從 key window 動態取得

`BannerView.rootViewController` 由當前 key window 的 root 提供。理由：banner 被點擊時需要一個 view controller 來呈現全螢幕的廣告內容。從 key window 動態取得可避免在 SwiftUI 環境中持有並傳遞 view controller 參考。

### app-ads.txt 的驗證鏈跨出 repo

app-ads.txt 託管於開發者網站根目錄。AdMob 爬蟲並非直接得知該網址，而是**從 App Store 商店資訊的「行銷 URL」取出 hostname**，再到該 hostname 的根目錄尋找檔案。因此驗證需要三者同時成立：檔案存在且可公開存取、行銷 URL 已填寫、且其 hostname 與檔案託管網域一致。v1.0.0 的實際情況是檔案正確、行銷 URL 留空，導致 AdMob 顯示「找不到 app-ads.txt 檔案」且連檢索網址都是空的——因為它根本推導不出要去哪裡找。此依賴的另一端（行銷 URL 欄位本身）屬 `app-store-listing` 的規範範圍。

## Implementation Contract

**Behavior (observable):**
- 首頁頂端顯示一個標示「廣告」的 banner，捲動清單時廣告固定在頂端且不被內容穿透。
- 沒有廣告可投放時，頂端不留任何空白或空框。
- 持有「移除廣告」的使用者看不到版位，且 app 不發出廣告請求。
- 點擊 banner 能正常開啟廣告內容。
- app 從不顯示追蹤許可（ATT）彈窗。

**Interface / data shape:**
- `AdConfig.homeBannerUnitID: String`：DEBUG 回傳 Google 測試單元、Release 回傳正式單元。
- `AdConfig.makeRequest() -> Request`：帶 `["npa": "1"]` 的 `Extras`。
- `AdSlotView`：無參數 SwiftUI view，內部維護 `loading` / `loaded` / `failed` 三態。
- `BannerAdView: UIViewRepresentable`：`adUnitID`、`onLoaded: (Bool) -> Void`；使用 `AdSizeBanner`（320x50）。
- SDK 於 `AppDelegate.application(_:didFinishLaunchingWithOptions:)` 內啟動。
- `Info.plist`：`GADApplicationIdentifier` 兩環境共用；無 `NSUserTrackingUsageDescription`。

**Acceptance criteria:**
- `grep -rn "ATTrackingManager\|NSUserTrackingUsageDescription" Sources project.yml` 無結果。
- `AdConfig.homeBannerUnitID` 的測試單元與正式單元分別位於 `#if DEBUG` 與 `#else` 分支。
- `AdSlotView` 僅在 `failed` 狀態下把高度、內距與背景同時歸零。
- `AdSlotView` 的建立由呼叫端以 `adsRemoved` 條件包裹，`AdSlotView` 內不含任何 IAP 相關判斷。
- 託管網域根目錄的 app-ads.txt 可公開存取，且內容含本 app 的 AdMob publisher ID。

**Scope boundaries:**
- In scope：SDK 初始化、請求設定與 ATT 立場、單元 ID 分流、版位載入狀態與收合、entitlement 抑制方式、app-ads.txt 的託管與依賴。
- Out of scope：購買流程與 entitlement 推導（`iap-remove-ads`）、首頁整體版面（`home-ui`）、行銷 URL 欄位的規範（`app-store-listing`）、UMP 同意流程。

## Risks / Trade-offs

- [行銷 URL 未填寫時，app-ads.txt 永遠無法驗證] → 未驗證狀態下部分廣告需求方不會出價，填充率與收益受損，且 AdMob 後台的錯誤訊息（「找不到 app-ads.txt 檔案」）指向檔案本身，容易讓人往錯誤方向排查。此欄位在已上架版本無法單獨修改，必須隨新版本送審。
- [非個人化廣告單價較低] → 這是刻意的取捨，換來最乾淨的隱私標籤與零 ATT 摩擦。若未來收益成為主要目標，改採個人化需要同時處理 ATT、隱私標籤與（若進入歐盟）UMP。
- [失敗後不重試] → 版位在一次載入失敗後即收合，該次畫面生命週期內不再嘗試。網路短暫異常會造成整段瀏覽期間都沒有廣告。以使用者體驗換取簡單性，但確實放棄了部分曝光。
- [`AdSizeBanner` 為固定 320x50] → 未採用自適應 banner，在較寬的裝置上未用滿可用寬度，收益略低於自適應尺寸。換得的是固定高度、排版可預測。
- [廣告 SDK 在啟動時即初始化] → 即使使用者已購買移除廣告，SDK 仍會啟動。這不會產生廣告請求，但仍有啟動成本與網路活動。
