## Summary

拿掉 `UITabBarController`，根控制器改為單一 `UINavigationController`；設定改由首頁導覽列右上角的齒輪 push 進入。

## Motivation

Tab bar 的用途是讓使用者在**會頻繁來回切換的並列目的地**之間移動。這個 app 的兩個 tab 不是那種關係：食材清單是主體，設定是一輩子大概只進去兩次的地方（開 iCloud 同步、購買移除廣告）。設定從屬於清單，不與它平起平坐。

代價是實際的垂直空間。iOS 26 的浮動 tab bar 連同邊距佔掉畫面底部約一列食材的高度，而首頁的清單正是在那一端被「Add Food」按鈕壓住——首頁本來就有內容被擠到摺線下的問題，tab bar 讓它更糟。

現在做的理由是首頁的版面調整正在討論中，而根控制器的形狀是那些調整的前提：清單能拿回多少空間，取決於底部還有沒有 tab bar。先把骨架定下來，版面才有得談。

## Proposed Solution

- 根控制器改為單一 `UINavigationController`，其 root 為首頁。
- 首頁導覽列右上角加一顆齒輪，push 進入設定頁；設定頁以標準返回鍵退回。
- 齒輪的觸發走既有的 MVVMC 路徑：View 的 toolbar 送出 ViewAction → ViewModel 發出導航意圖 → HostController 交給 `AppRouter` 執行。不在 HostController 直接掛 UIKit 的 bar button。
- 三個 deeplink 進入點改為從單一 navigation stack 取得首頁，不再經由 tab 控制器。
- 隨 tab bar 一起失去意義的東西一併移除：`AppRouter` 的切換分頁方法、首頁分頁索引常數、把 root 包成 tab 的輔助方法、`INITIAL_TAB` 這個 DEBUG 環境開關，以及表單上那句「推入時隱藏 tab bar」的設定。

## Non-Goals (optional)

- **不改首頁版面**。環形圖、浪費統計、清單順序、空狀態全部維持現狀。拿回來的空間這次不重新分配——那是後續討論的題目，混進來會讓 deeplink 出問題時分不清是誰造成的。
- **不改設定頁本身**的內容、排版或任何互動。
- **不改 `Deeplink` 的 URL 格式**。對外的 `foodentropy://home` 與 `foodentropy://item/<uuid>` 完全不變，只有 app 內部如何抵達首頁的實作改變。
- 不把設定改成 sheet。已評估並否決，理由見 design。
- 不處理移除廣告內購的曝光度變化（設定收進齒輪後 IAP 入口變得較不顯眼）。那是獨立的產品題目。

## Alternatives Considered (optional)

- **設定改以 sheet 呈現**：語意上「設定是岔路而非內容階層的更深一層」較貼切。否決，理由見 design 的〈設定以 push 而非 sheet 呈現〉。
- **保留 tab bar 但把設定換成別的東西**（例如把統計拆成第二個 tab）：等於用新增畫面來正當化一個不該存在的容器，且與「首頁承載總覽與工作清單」的既有 requirement 衝突。

## Impact

- Affected specs: `app-shell`（修改）、`navigation`（修改）、`home-ui`（修改）
- Affected code:
  - Modified:
    - `Sources/App/SceneDelegate.swift`
    - `Sources/App/AppRouter.swift`
    - `Sources/Features/Home/HomeView.swift`
    - `Sources/Features/Home/HomeViewModel.swift`
    - `Sources/Features/Home/HomeHostController.swift`
    - `Sources/Features/Settings/SettingsView.swift`
    - `Sources/Features/FoodForm/FoodFormHostController.swift`
    - `Sources/Resources/Localizable.xcstrings`
    - `Tests/FoodEntropyTests/HomeViewModelTests.swift`
  - New: (none)
  - Removed: (none)
