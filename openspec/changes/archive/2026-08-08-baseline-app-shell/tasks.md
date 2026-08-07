## 1. Baseline 文件化

- [x] 1.1 從 `Sources/App/AppDelegate.swift` 與 `project.yml` 的 `UIApplicationSceneManifest` 寫出 requirement「The app boots through a UIKit AppDelegate and SceneDelegate」；驗證：`grep -c "@main" Sources/App/AppDelegate.swift` 為 1，且 `grep -rn "SwiftUI.App\|: App {" Sources` 無結果。
- [x] 1.2 從 `SceneDelegate.scene(_:willConnectTo:)`、`makeManager()`、`makeRootTabBarController(manager:store:)` 寫出 requirement「SceneDelegate is the single composition root」；驗證：兩個 HostController 的 `init` 皆收注入的 manager／store 參數（`HomeHostController(manager:store:)`、`SettingsHostController(store:)`），且 `grep -rn "StoreManager(" Sources` 在 runtime 路徑上僅命中 `SceneDelegate.swift`——`HomeView.swift` 與 `SettingsView.swift` 的命中皆位於 `#Preview` 區塊內，不屬 runtime 路徑。
- [x] 1.3 從 `SwiftDataManager.makeResilient(cloudKitEnabled:)` 寫出 requirement「Store creation degrades rather than failing the launch」；驗證：`makeResilient` 簽章不 throw，且函式內可見 CloudKit → 本機 → 記憶體三段 fallback。
- [x] 1.4 從 `makeRootTabBarController` 與 `wrapInTab` 寫出 requirement「The root is a two-tab controller with per-tab navigation stacks」；驗證：`tabBarController.viewControllers` 為兩項，且 `wrapInTab` 回傳 `UINavigationController`。
- [x] 1.5 從 `SceneDelegate` 內 `SCREENSHOT_MODE` / `SEED_MOCKS` / `INITIAL_TAB` 三處寫出 requirement「Debug-only environment switches are excluded from Release builds」；驗證：`grep -n "SCREENSHOT_MODE\|SEED_MOCKS\|INITIAL_TAB" Sources/App/SceneDelegate.swift` 命中的每一行都落在 `#if DEBUG` 與對應 `#endif` 之間。
- [x] 1.6 從 `window.backgroundColor = .systemBackground` 寫出 requirement「The window uses an opaque semantic background colour」；驗證：`grep -n "window.backgroundColor" Sources/App/SceneDelegate.swift` 命中且值為語意色而非固定色。
- [x] 1.7 從 `project.yml` 與 `specs/00-constitution.md` 寫出 requirement「The platform envelope is iPhone-only, portrait, iOS 26 or later」；驗證：`project.yml` 內 `TARGETED_DEVICE_FAMILY: "1"`、`deploymentTarget.iOS: "26.0"`、`SWIFT_STRICT_CONCURRENCY: complete`、`UISupportedInterfaceOrientations` 僅含 `UIInterfaceOrientationPortrait`。
- [x] 1.8 從 `.gitignore` 與憲章的 XcodeGen 決定寫出 requirement「The Xcode project is generated from project.yml」；驗證：`git check-ignore -v FoodEntropy.xcodeproj` 回傳 `.gitignore` 規則且 `git ls-files FoodEntropy.xcodeproj` 為空。
- [x] 1.9 從 `Sources/` 實際目錄結構寫出 requirement「Source files follow the MVVMC folder convention」；驗證：`find Sources/Features -maxdepth 1 -type d` 的每個 feature 目錄下都同時存在 `*HostController.swift`、`*View.swift`、`*ViewModel.swift`、`*ViewModel+Models.swift`。

## 2. 收尾

- [x] 2.1 執行 `spectra validate baseline-app-shell` 確認四份 artifact 與 spec 格式通過；驗證：指令回傳成功、無 error。
- [x] 2.2 archive 後補上 `openspec/specs/app-shell/spec.md` 的 `## Purpose` 段（CLI 會留下 TBD 佔位）；驗證：`grep -c "TBD" openspec/specs/app-shell/spec.md` 為 0。
