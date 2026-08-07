## Summary

補回 v1.0.0 的廣告 baseline：非個人化請求與「不跳 ATT」的合規立場、開發與正式廣告單元的編譯期分流、無 fill 時收合版位、由 IAP entitlement 決定是否放入版位，以及 app-ads.txt 的驗證前提。無行為變更。

## Motivation

廣告這一層有三件事需要規格保護：

**一、「不跳 ATT」是刻意的合規判斷，不是漏做。** 直覺會認為「有廣告就該跳 ATT」，但 ATT 只在要追蹤（存取 IDFA 做跨 App 個人化）時才必要且必須。本 app 送出的是非個人化請求（`npa=1`），不碰 IDFA，此時硬跳 ATT 反而可能因「無意義的權限請求」被 Apple 依 Guideline 5.1.2 退件。若後來的人「補上」ATT，等於引入退件風險。

**二、開發階段用正式廣告單元會被 AdMob 停權。** 用自己的正式單元自我測試屬於無效流量，可能導致帳號被停用。因此單元 ID 以 `#if DEBUG` 分流，開發一律用 Google 官方測試單元。這個保護一旦被「簡化」成單一常數，違規是靜默發生的——直到帳號被停。

**三、app-ads.txt 的驗證鏈有一環在 repo 之外。** AdMob 爬蟲是從 App Store 商店資訊的「行銷 URL」取得網域，再去該網域根目錄尋找 app-ads.txt。v1.0.0 上架時行銷 URL 留空，導致爬蟲無從得知該去哪個網域，app-ads.txt 因而始終處於「找不到檔案」狀態——檔案本身部署正確且可存取。這個跨越 repo 與 App Store Connect 的依賴目前沒有任何地方記錄。

## Proposed Solution

從 `Sources/Core/Ad/AdConfig.swift`、`AdSlotView.swift`、`BannerAdView.swift`、`AppDelegate` 的初始化、`HomeView` 的放入條件與 `specs/02-architecture.md` §9 寫出 `advertising` capability spec，涵蓋：SDK 初始化時機、非個人化請求與 ATT 立場、單元 ID 的編譯期分流、版位的三種載入狀態與收合行為、與 `iap-remove-ads` 的抑制關係，以及 app-ads.txt 的託管與行銷 URL 前提。

## Non-Goals

- 無行為變更。
- 不涵蓋購買與 entitlement 的推導，那屬 `iap-remove-ads`；本 capability 只規範「持有時不放入版位」。
- 不涵蓋首頁的整體版面，那屬 `home-ui`；本 capability 只規範版位自身的行為。
- 不涵蓋 App Store Connect 上行銷 URL 的實際填寫狀態——該欄位的規範歸 `app-store-listing`，本 capability 只記錄 app-ads.txt 對它的依賴。
- 不涵蓋 UMP 同意流程：排除歐盟發行，v1.0.0 不主動接入。

## Capabilities

### New Capabilities

- `advertising`：AdMob 初始化、非個人化請求與 ATT 立場、單元 ID 編譯期分流、版位載入狀態與收合、entitlement 抑制、app-ads.txt 前提。

### Modified Capabilities

（無）

## Impact

- Affected specs: new `advertising`
- Affected code:
  - New: （無 —— 記錄既有程式碼）
  - Modified: （無）
  - Removed: （無）
  - Reference: `Sources/Core/Ad/AdConfig.swift`, `Sources/Core/Ad/AdSlotView.swift`, `Sources/Core/Ad/BannerAdView.swift`, `Sources/App/AppDelegate.swift`, `Sources/Features/Home/HomeView.swift`, `project.yml`, `specs/02-architecture.md`
