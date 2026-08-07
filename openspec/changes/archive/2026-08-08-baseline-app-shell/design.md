## Context

FoodEntropy 用 UIKit 生命週期（AppDelegate + SceneDelegate）承載 SwiftUI，而非 SwiftUI `@main App`。這不是沿用舊習慣，而是 MVVMC 的必要條件：`AppRouter` 操作的是 `UINavigationController` / `UITabBarController`，HostController 是 `UIHostingController` 子類，這些都需要一個真正的 UIKit 場景生命週期才有得掛。

v1.0.0 上架前的實作過程中，shell 累積了幾個「程式碼裡看得到、但理由只寫在註解」的決策——store 建立失敗的降級鏈、DEBUG-only 環境開關、`window.backgroundColor` 的防黑底。這份 baseline 把它們固定成規格，讓未來的重構不會把它們當成雜訊清掉。

## Goals / Non-Goals

**Goals:**
- 記錄 UIKit 生命週期進入點是架構前提，不是可替換的風格選擇。
- 記錄 SceneDelegate 作為唯一 composition root 的注入方向。
- 記錄 store 建立的三層降級鏈，以及它防的是什麼（開機即崩的 crash loop）。
- 記錄 DEBUG-only 逃生門必須留在 `#if DEBUG` 內的不變式，及其違反後果。
- 記錄平台外框與 XcodeGen 生成慣例。

**Non-Goals:**
- 無行為變更。
- 不重述 mvvmc-* skills 的規則。
- 不涵蓋 `navigation`、`persistence`、`notification`、`iap-remove-ads`、`advertising` 各自的內部行為。

## Decisions

### 進入點是 AppDelegate + SceneDelegate，不是 SwiftUI @main App

`AppDelegate` 標 `@main`，`Info.plist` 的 `UIApplicationSceneManifest` 指向 `$(PRODUCT_MODULE_NAME).SceneDelegate`，由 SceneDelegate 建立 `UIWindow` 並設定 `rootViewController`。SwiftUI 只從 `UIHostingController` 以下開始。理由：MVVMC 的 C 層（`AppRouter`）直接操作 `UINavigationController` 與 `UITabBarController`，SwiftUI 的 `NavigationStack` 無法提供等價的命令式控制，也接不上 `UIViewControllerAnimatedTransitioning` 自訂轉場。考慮過的替代方案：SwiftUI `@main App` + `NavigationStack`——否決，因為那等於放棄整個 MVVMC 的 Router 模型，而 Router 是本專案（與其他專案共用的 mvvmc-* skills）的架構基礎。

### SceneDelegate 是唯一 composition root，依賴一律由外往內注入

`SwiftDataManager` 與 `StoreManager` 只在 `scene(_:willConnectTo:)` 各建立一次，由 SceneDelegate 持有，再注入 `HomeHostController` / `SettingsHostController`，HostController 再往下傳給 ViewModel。HostController 與 ViewModel 一律不自行建立這兩者。理由：兩者都是有狀態的單一真相來源——`StoreManager` 持有 IAP entitlement 並監聽交易更新，`SwiftDataManager` 持有 `ModelContainer`；若各畫面自建實例，購買「移除廣告」後首頁的廣告不會消失（各自持有不同的 entitlement 副本），資料層也會出現多個 container。SceneDelegate 額外持有 `manager` 是為了在 `sceneDidBecomeActive` 對帳通知排程（詳見 `notification`）。考慮過的替代方案：全域 singleton——否決，會讓測試無法替換，也違反 mvvmc-viewmodel 的注入慣例。

### store 建立走三層降級，永不讓啟動失敗

`SwiftDataManager.makeResilient(cloudKitEnabled:)` 依序嘗試：CloudKit 容器 → 純本機 → 記憶體。理由：`ModelContainer` 建立失敗會拋錯，若讓它傳播就是啟動即崩；而崩潰發生在啟動階段時使用者無法自救（連進設定關掉 iCloud 同步的機會都沒有），只會反覆閃退——App Store 上的一星評價與退件多半來自這種 crash loop。降級後 app 仍可開啟，使用者至少能操作、能關掉同步。考慮過的替代方案：建立失敗直接 `fatalError` 並回報——否決，對已上架的 app 而言，可用性優先於錯誤可見性；崩潰資訊仍可從 Xcode Organizer 取得。

### root 是兩 Tab 的 UITabBarController，每個 Tab 各包自己的 UINavigationController

`UITabBarController` 裝兩個 Tab（首頁、設定），每個 Tab 的 root 都用 `UINavigationController` 包起來。理由：`AppRouter` 是 push-based，`to()` 需要從 `source.navigationController` 動態取得堆疊；每 Tab 各有獨立堆疊，切 Tab 才不會互相干擾彼此的 push 深度。這也是 `navigation` 的 `AppRouter.tab(_:from:)` 能運作的前提——它從 `source.tabBarController` 取得 tab bar。考慮過的替代方案：單一 `UINavigationController` 當 root、以 push 切換首頁/設定——否決，Tab 是同層並列的兩個入口，不是有前後關係的堆疊。

### DEBUG-only 逃生門一律包在 #if DEBUG 內

`SCREENSHOT_MODE`、`SEED_MOCKS`、`INITIAL_TAB` 三個環境變數開關全部包在 `#if DEBUG`。其中 `SCREENSHOT_MODE=1` 會以 `StoreManager(adsRemoved: true)` 建立 store——亦即直接把「移除廣告」entitlement 設為已購買。理由：這條路徑若編進 Release build，任何人都能用環境變數白拿付費功能，而且它繞過的是 StoreKit 的購買驗證本身，不是 UI 層的顯示判斷。`#if DEBUG` 是編譯期移除，Release 產物裡不存在這段程式碼，這是唯一可接受的隔離強度。考慮過的替代方案：以 runtime flag 加上 `isDebuggerAttached` 之類的檢查——否決，runtime 檢查可被繞過，且付費解鎖路徑不該有任何 runtime 後門。

### window 設定不透明背景色以防轉場露黑底

`window.backgroundColor = .systemBackground`。理由：`navigation` 的自訂轉場動畫（modal / fade）期間，容器視圖會短暫露出 window 底色，預設的黑色在淺色模式下是明顯的閃黑。用語意色而非固定色，才能同時對上深淺兩種模式。

### 專案由 XcodeGen 生成，.xcodeproj 不進版控

`project.yml` 是專案設定的唯一真實來源，`.xcodeproj/` 在 `.gitignore` 內。理由：`.xcodeproj` 是難以審閱、極易衝突的生成物；單人專案雖無合併衝突問題，但把設定寫成可讀的 yml 才能讓設定變更在 diff 中被看見（例如 build number、entitlements、SKAdNetwork 清單）。代價：clone 後必須先跑 `xcodegen generate` 才有專案可開。

## Implementation Contract

**Behavior (observable):**
- 冷啟動後顯示兩 Tab（首頁、設定），預設停在首頁。
- iCloud 同步開啟但 CloudKit 容器不可用時，app 仍正常啟動，資料落在本機。
- 購買「移除廣告」後首頁廣告消失，且切換 Tab、重啟後維持消失。
- Release build 不受 `SCREENSHOT_MODE` / `SEED_MOCKS` / `INITIAL_TAB` 任何環境變數影響。
- 裝置旋轉時畫面維持直向。

**Interface / data shape:**
- `AppDelegate`：`@main`，`didFinishLaunchingWithOptions` 內啟動 AdMob（見 `advertising`），提供 `UISceneConfiguration`。
- `SceneDelegate`：`@MainActor`，持有 `window` / `manager: SwiftDataManager?` / `store: StoreManager?`；`makeManager()` 與 `makeRootTabBarController(manager:store:)` 為 private composition step。
- `SwiftDataManager.makeResilient(cloudKitEnabled: Bool) -> SwiftDataManager`：不 throw，必定回傳可用實例。
- 資料夾配置：`Sources/App`（shell 與 Router）、`Sources/Core`（跨畫面共用：Domain / Persistence / Notification / Store / Ad / Image / Components / Extensions）、`Sources/Features/<Feature>/`（`<Feature>HostController` + `<Feature>View` + `<Feature>ViewModel` + `<Feature>ViewModel+Models`）。

**Acceptance criteria:**
- `grep -c "@main" Sources/App/AppDelegate.swift` 為 1，且 `Sources` 下無 SwiftUI `App` 協定實作。
- `SCREENSHOT_MODE` / `SEED_MOCKS` / `INITIAL_TAB` 每一處出現都落在 `#if DEBUG` 區塊內。
- `project.yml` 的 `TARGETED_DEVICE_FAMILY` 為 `"1"`、`UISupportedInterfaceOrientations` 僅含 `UIInterfaceOrientationPortrait`、`deploymentTarget.iOS` 為 `"26.0"`、`SWIFT_STRICT_CONCURRENCY` 為 `complete`。
- `git check-ignore FoodEntropy.xcodeproj` 成立。

**Scope boundaries:**
- In scope：進入點、composition root 與注入方向、store 降級鏈、tab bar root 結構、平台外框、DEBUG 隔離、XcodeGen 慣例、MVVMC 資料夾配置。
- Out of scope：`AppRouter` 導航語意與 `Deeplink` 解析（`navigation`）、SwiftData schema 與 CloudKit 約束（`persistence`）、通知排程規則（`notification`）、IAP 購買與還原流程（`iap-remove-ads`）、廣告載入與收合行為（`advertising`）。

## Risks / Trade-offs

- [三層降級會靜默吞掉 store 建立失敗] → 使用者可能在不知情下以本機模式運行、以為 iCloud 同步正在作用；接受此代價，因為替代方案是開機即崩。降級事件在 `persistence` 的範圍內可考慮加上使用者可見的提示，但不由 shell 處理。
- [`.xcodeproj` 不進版控] → clone 後無法直接開啟專案，須先 `xcodegen generate`；單人專案影響有限，且換來設定變更在 diff 中可審閱。
- [SceneDelegate 同時持有 manager 與 store] → shell 承擔了部分生命週期職責（前景對帳），使它不是純粹的裝配器；接受，因為這兩個對帳動作都需要場景層級的生命週期事件，往下放到任何一個 feature 都會讓該 feature 承擔不屬於它的全域責任。
