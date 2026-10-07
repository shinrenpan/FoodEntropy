## Context

iPhone Duo 是書本式摺疊 iPhone。外螢幕（466×678pt）會遵守 app 宣告的方向，內螢幕（669×951pt，直橫皆 regular／regular）不理會。食熵只宣告直立，所以內螢幕轉橫向時以橫向全螢幕執行，首頁被拉寬。iOS 27.1 SDK 新增 `ArrangementView`／`UIArrangementViewController`（並排兩個 view 並避開折線）與 `reservedRegions(kind: .division)`（回報折線位置）。

2026-10-06～07 在 iPhone Duo 模擬器（Xcode 27.1 RC 27A9275，iOS 27.1 24A94232）依序試過四種做法，結論與實測依據都記錄在下方 Decisions。參考實作在 branch experiment/duo-hstack-fold（ec0069f），本 change 以它為底，補上測試與規格。

Apple 對 Duo 版面的官方順序是：標準容器（split view）→ `ArrangementView` → 自己排版並讀 reserved regions。本 change 停在第三層，每一層往下的理由見 Decisions。

## Goals / Non-Goals

**Goals:**

- 內螢幕橫向時設定在左、首頁在右；其他情況與現行完全相同。
- 兩欄依折線分界，半開不壓折線，全開與半開切換時分界不跳動。
- 單欄與兩欄互轉時首頁不重建，sheet、捲動位置、載入狀態都保留。
- 廣告在任何轉換下都留在首頁欄內。
- 移除廣告的 entitlement 改變時，所有顯示中的畫面立即更新。
- 一般 iPhone 的行為與現行完全相同，iOS 26 也能執行。

**Non-Goals:**

- 不使用 `ArrangementView`、`UISplitViewController`、`UIArrangementViewController`（理由見 Decisions）。
- 不處理內螢幕直向半開時的橫向折線（直向只顯示首頁，可捲動內容依 Apple 原則不需避開）。
- 不修既有的「分桶清單 sheet 開著時 deeplink 被推到 sheet 底下」缺陷，另開 change。
- 不開啟多 scene；不處理 `BannerAdView` 與 `AppRouter.deeplink` 從全域 scene 找 window 的寫法（單一 scene 下無害）。
- 不重新設計左欄內容，左欄就是既有設定頁。
- 不調整兩欄共用一條導覽列時標題的位置（標題「首頁」顯示在 leading 側、位於設定欄上方，作者已接受）。

## Decisions

### Lay out two columns with HStack and reserved regions

在首頁 host 的 SwiftUI 內容最外層加一個 `HomeRootView`：用 `GeometryReader` 取得外層提供的空間，寬大於高時 `HStack { SettingsView; HomeView }`，否則只放 `HomeView`。

考慮過的替代方案（都在 Duo 模擬器實測過）：

- **`ArrangementView` `.split`**：會自動讓出折線、自動收合，但 split 沒有指定 primary 落在哪一側的 API（27.1 SDK 比對，HIG 也寫 primary 在 leading），首頁只能在左。把首頁改當 secondary 並給 `layoutPriority`，內螢幕直向仍然分兩欄，不會收合。
- **`UISplitViewController`**：column 樣式收合時把 secondary（首頁的 nav）推到 primary（設定）的堆疊上，首頁出現返回鈕、堆疊的根變成設定，Router 的 `backToRoot`／`resetTo` 與 deeplink 都依賴「堆疊根是首頁」。classic 寫法在 iOS 27 SDK 斷言失敗（`already specified as the view controller for the secondary column`）。
- **`UIArrangementViewController` 子類、尺寸改變時互換 primary**：MVVMC Experiments/PaneProbe 驗證可行（含半開自動避開折線），但所有 iOS 27.1 iPhone 都會經過容器的收合、按鈕轉接、標題邏輯，而 27.1 模擬器 runtime 只支援 Duo，一般 iPhone 目前測不到；另外要為 iOS 26 寫 fallback、自行轉接 pane 的導覽列按鈕。等一般 iPhone 能測 27.1 時另開 change 改用。

### Measure the space given, not the content

判斷「是否兩欄」與計算欄寬時，量的是 `GeometryReader` 收到的外層提案，不是 `HStack` 自身的尺寸。量 `HStack` 會被已設定的固定欄寬撐住：轉回直向時右欄仍是上一輪的半寬，量到的仍是寬大於高，永遠退不回單欄（實測）。

兩欄都給確定寬度（`.frame(width:)`）。只給 `maxWidth: .infinity` 時，轉換後兩欄的寬度分配不固定，實測同一姿態出現過 1:1 與 2:1。

首頁在 `HStack` 中永遠是同一個位置的子 view，兩欄與單欄的差別只在是否插入左欄，所以切換時首頁的 identity 不變。

### Column boundary follows the fold

讀 `GeometryProxy.reservedRegions(kind: .division, options: .includeInactive)`，取高大於寬的那一個（直向折線）：

- 折線啟用（半開）：左欄寬 = 折線 minX，間距 = 折線寬，右欄 = 容器寬 − 折線 maxX。
- 折線未啟用（平放）：分界在折線 midX，間距 0。
- 沒有折線（不是 Duo，或 iOS 27.1 以下）：各占一半。

不用「容器寬的一半」當平放時的分界：容器扣掉了右側的垂直 bar，一半不等於實體折線，半開與全開切換時卡牌欄會一次跳約 60pt（實測）。

實測數值（容器 867×553pt）：折線固定在 455–495pt、寬 40，不隨彎曲角度改變；平放時 `isActive == false`，任何彎曲角度都是 `true`。

把欄寬計算抽成純值型別（輸入容器尺寸與折線矩形、啟用狀態），讓上述三種情況可以用單元測試涵蓋，不必依賴模擬器。

`reservedRegions` 只在 iOS 27.1 以上可用，以 `#available` 保護；低版本視為沒有折線。

### Compose settings inside the home host

並排時，設定是嵌在 `HomeHostController` 的 SwiftUI 內容裡的 `SettingsView`，由首頁 host 持有一個 `SettingsViewModel`，並代為執行它的導航意圖（開隱私權政策 sheet、跳系統通知設定）。導航邏輯由 `SettingsHostController.handle(_:from:)` 提供，推入的設定頁與嵌入的設定共用，避免寫兩份。

嵌入時 `SettingsView` 不設定 `navigationTitle`：兩欄共用同一條導覽列，嵌入的這欄若設標題會蓋掉首頁的標題，從外層再指定也蓋不回（實測）。

這兩點是已知架構債（MVVMC，2026-10-07）：static `handle(_:from:)` 讓首頁 host 跨 feature 呼叫設定 host；`isEmbedded` 讓 feature 知道自己的呈現環境。MVVMC PaneProbe 已驗證解法——每欄改為完整 HostController（由 representable 包裝或 `UIArrangementViewController` 容器），pane 開出的 sheet 在收合後仍存活。改用容器時一併移除。

實測佐證目前寫法可行：兩欄時從左欄開隱私權政策 sheet，闔上裝置後 sheet 仍存活並轉為外螢幕全螢幕 sheet。

### Pushed settings yields when the space widens

`SettingsHostController` 在 `viewWillTransition(to:with:)` 中，若新尺寸寬大於高，於轉場完成後經 `AppRouter.back(from:)` 退回（不帶動畫）。轉場完成後才改動堆疊，避免在尺寸變化中途改動 stack。只有被推入的設定頁才會在堆疊上，嵌入的設定沒有自己的 host，不受影響。

判斷條件與 `HomeRootView` 共用 `SideBySideLayout.isWide(_:)`，不各寫一份。

### Bridged banner sizes from the proposal

`BannerAdView` 實作 `sizeThatFits(_:uiView:context:)`，回傳「提案寬度 × 固定 banner 高度」；提案寬度為 nil 或無限大時退回 banner 的標準寬度。AdMob 的 `BannerView` 會把自報寬度撐到上一次被排到的寬度、之後不縮回，單欄轉兩欄時就溢出到鄰欄（13.7.0 與 13.11.0 皆實測重現）。此規則已由 MVVMC 寫入 mvvmc-view（第三方 SDK 的 view 一律實作）。

`AdSizeBanner` 是固定 320×50 的格式，所以寫死高度正確；若之後改用 adaptive banner，高度要改用 SDK 的尺寸函式計算。

### Announce entitlement changes

`StoreManager` 在 `adsRemoved` 實際改變時發出 `StoreManager.didChangeNotification`（值相同不發）。首頁與設定頁都監聽它並重讀。比照既有的 `SwiftDataManager.didChangeNotification` 模式。

不靠 `onAppear`：兩欄時設定與首頁都常駐，不會再出現；退款與他機購買也可能在背景經 `Transaction.updates` 改變。

設定頁另外監聽 `UIApplication.didBecomeActiveNotification`，從系統設定回來時重讀通知權限。UIKit 生命週期收不到 SwiftUI 的 `scenePhase`。

### Keep the portrait declaration and require AdMob 13.11.0

保留 `UISupportedInterfaceOrientations` 只有 Portrait：一般 iPhone 與 Duo 外螢幕都靠它鎖直立（外螢幕實測遵守，MVVMC demo 未宣告時則跟著轉，成對照）；只有內螢幕不理會。

`project.yml` 的 GoogleMobileAds 最低版本改為 13.11.0（官方 release notes：13.10.0 支援 iOS 27、13.11.0 正式支援 iPhone Duo）。`Package.resolved` 不進版控，只靠本機解析會因環境不同解析回舊版。

## Implementation Contract

**行為：**

- 一般 iPhone、Duo 外螢幕、Duo 內螢幕直向：畫面與現行完全相同（只有首頁，導覽列有設定按鈕）。
- Duo 內螢幕橫向（全開或半開）：設定在左、首頁在右，首頁導覽列沒有設定按鈕；半開時兩欄之間留出折線寬度、顏色與兩欄背景相同。
- 單欄與兩欄互轉：首頁不重建，開著的 sheet 保留。
- 推入的設定頁在變成兩欄時自動退回。
- 廣告在任何轉換下都不超出首頁欄。
- 在設定欄購買移除廣告後，首頁廣告立即消失。

**介面：**

- `HomeRootView(homeViewModel:settingsViewModel:)`：`HomeHostController` 的 root view。
- 欄寬計算：純值型別，輸入容器 `CGSize` 與可選的折線（`CGRect` 與是否啟用），輸出是否兩欄、左欄寬、間距、右欄寬。
- `HomeView(viewModel:showsSettingsButton:)`，`showsSettingsButton` 預設 `true`。
- `SettingsView(viewModel:isEmbedded:)`，`isEmbedded` 預設 `false`。
- `SettingsHostController.handle(_:from:)`：static，執行 `SettingsViewModel.Router`。
- `StoreManager.didChangeNotification`。

**失敗模式：**

- iOS 27.1 以下或沒有折線：分界退回容器寬的一半，不報錯。
- 折線矩形不落在容器內（例如分割畫面時只剩一條細縫）：視為沒有折線。

**驗收：**

- 單元測試涵蓋欄寬計算的三種情況（窄、寬無折線、寬有啟用／未啟用折線），使用上方實測數值。
- 既有測試全部通過（目前 132 個）。
- iPhone Duo 模擬器手動驗證：外螢幕、半開、全開、內螢幕直向、直向→橫向、推入設定後翻開或轉橫、全開開 sheet 後闔上、在設定欄購買移除廣告。
- iPhone 18 Pro（iOS 27.0）模擬器：只顯示首頁、有設定按鈕、沒有返回鈕。

**範圍：**

- 範圍內：上述行為、`project.yml` 的 AdMob 版本、`CLAUDE.md` 與 `openspec/config.yaml` 的平台方向描述。
- 範圍外：Non-Goals 所列各項。

## Risks / Trade-offs

- [27.1 的一般 iPhone 無法在模擬器驗證] → 本方案在窄空間的路徑就是原本的 `HomeView`，`reservedRegions` 只在寬空間才讀，一般 iPhone 的行為改變最小。
- [折線邏輯只處理一條直向折線] → 內螢幕直向半開時不讀橫向折線，依 Apple 原則可捲動內容不需避開；之後改用 `UIArrangementViewController` 時由系統處理。
- [兩條寬高判斷（`HomeRootView` 與 `SettingsHostController`）可能漂移] → 已合併為單一出處 `SideBySideLayout.isWide(_:)`，兩處共用並有單元測試。
- [只看寬大於高，不看 size class] → Duo 外螢幕橫放是 678×466、compact，若日後解除直立鎖定，會被誤判為兩欄。目前因直立鎖定碰不到；解除鎖定的 change 必須同時加入 size class 判斷。
- [AdMob 固定高度] → 若改用 adaptive banner，`sizeThatFits` 的高度要跟著改。
- [已知架構債兩筆] → 已記錄解法與改用條件（一般 iPhone 能測 iOS 27.1 時）。
