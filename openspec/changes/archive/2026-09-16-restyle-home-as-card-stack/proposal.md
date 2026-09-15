## Summary

首頁改為五張卡牌堆疊（Current／Waste Stats／過期／3 天內／保存期限內），選中的卡移到最前面完整顯示；食材清單從首頁移出，改由 sheet 內的獨立畫面呈現。

## Motivation

首頁現在同時是儀表板與工作檯，兩個角色互相排擠。實測量過：環形圖與浪費統計兩張卡佔掉整個第一屏，第一筆食材要到 70% 高度才出現，而且馬上被底部的「Add Food」壓掉一半。使用者打開 app 是要問「什麼快壞了」，卻得先滑過兩張統計卡。

更麻煩的是**資訊重複**：環形圖說「1 過期／3 快到期／1 新鮮」，下面三個 section header 又寫一次「Expired, unhandled 1 item」「Expiring within 3 days 3 items」。同一份資料講兩次，其中一次還佔掉半個螢幕。

浪費率則是**落後指標放在最顯眼的位置**——已經發生的事，使用者此刻無法對它做任何動作，而真正能行動的那筆（今天到期的優格）在摺線下方。

卡牌堆疊讓五個區塊共用一塊空間：一次只有一張完整顯示，其餘露出頂緣供選擇。清單移進 sheet 之後，首頁的角色變得單純——它是儀表板，工作檯在 sheet 裡。

這個設計已在 `experiment/home-card-stack` 分支以可運行的 spike 驗證過版面與高度（該分支的 commit 訊息記錄了設計結論與已知未解項）。本提案依驗證結果撰寫，實作時重寫，不沿用 spike 的程式碼。

## Proposed Solution

- 首頁主體改為一疊五張卡：Current、Waste Stats、過期、3 天內到期、保存期限內。未選中者被下一張壓住只露出頂緣，選中者排在最後完整顯示。
- 點卡片只把它移到最前面。已在最前面的分桶卡再點一次才開啟該桶的清單；卡面上以指示符號提示這一步。摘要卡與空的分桶卡沒有該提示，也不會開啟任何東西。
- 分桶清單移到 sheet：sheet 內是完整的清單畫面，擁有自己的導覽堆疊，因此點食材開啟編輯表單時是推在 sheet 內，關閉後退回清單而非首頁。
- 卡面內容一律是兩個真實事實：金額（這一桶損失或即將損失多少）與時間（最近一筆多久到期）。沒有已記錄價格時，時間升為主要資訊。
- 分桶卡的內容區高度固定，切換分桶時整疊不跳動。
- 底部「Add Food」的下緣間距維持現值，但其註解所述理由（與 tab bar 拉開距離）已隨 tab bar 移除而失效，一併更正。
- 助理的螢幕感知標註隨食材列一起移到分桶清單畫面：標註的對象是「畫面上的食材列」，而那些列不再位於首頁。

## Non-Goals (optional)

- **不改食材列本身**的外觀與四個動作。清單只是換了容器，列的點擊／滑動／長按行為完全不動。
- **不改資料層、通知、Widget、設定頁、表單**。
- **不改浪費統計與環形圖的內容**，只改它們被呈現的位置與時機。
- 不引進新的第三方相依，不加動畫框架。
- 不處理「浪費率是落後指標，是否該換成正面框架（近 30 天省下多少）」——那是獨立的產品題目，本次只改版面歸屬。
- 不沿用 spike 分支的程式碼。該分支數處為求快速驗證而抄近路（版面元件直接吃整個 State、型別退化成空殼、無單元測試），實作時依規格重寫。

## Alternatives Considered (optional)

- **把環形圖與浪費統計併成左右翻頁的摘要區，下方維持清單**：spike 驗證過，可行且省下約 250pt，但首頁仍是「儀表板 + 工作檯」的混合體，而且清單若要做成卡片容器就得離開 `List`，四個滑動手勢必須自行重寫。否決，因為卡牌堆疊加 sheet 同時解決了版面與手勢兩件事。
- **食材本身做成卡片堆疊**：卡片數量隨食材增加而不可控，且堆疊狀態下無法對單列滑動，最高頻的動作會從一個手勢變成兩個。否決。
- **扇形卡牌**：以遮擋換視覺效果，對「名稱 + 到期日」這種文字內容是致命的，且點擊區重疊、不隨數量縮放。否決。
- **點分桶卡即自動開啟清單**：少一次點擊，但使用者因此無法單純瀏覽這疊卡——任何一次點擊都會被丟進 modal。否決。

## Impact

- Affected specs: `home-ui`（修改）、`navigation`（修改）、`app-intents`（修改）
- Affected code:
  - New:
    - `Sources/Features/BucketList/BucketListView.swift`
    - `Sources/Features/BucketList/BucketListViewModel.swift`
    - `Sources/Features/BucketList/BucketListViewModel+Models.swift`
    - `Sources/Features/BucketList/BucketListHostController.swift`
    - `Tests/FoodEntropyTests/BucketListViewModelTests.swift`
  - Modified:
    - `Sources/Features/Home/HomeView.swift`
    - `Sources/Features/Home/HomeViewModel.swift`
    - `Sources/Features/Home/HomeViewModel+Models.swift`
    - `Sources/Features/Home/HomeHostController.swift`
    - `Sources/Core/Components/StatusChartView.swift`
    - `Sources/Resources/Localizable.xcstrings`
    - `Tests/FoodEntropyTests/HomeViewModelTests.swift`
    - `project.yml`
  - Removed: (none)
