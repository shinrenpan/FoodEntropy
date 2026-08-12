## Summary

加入一個**免費**的中尺寸主畫面 Widget，一眼顯示食材效期概況。版面與首頁「現況」區塊完全相同——同一份實作，不是相似的複製品。定位是下載誘因與日常曝光，刻意保持簡單：不含提醒功能、不做付費分層、不做互動操作、不做鎖定畫面。技術前提與 UI 皆已於 2026-08-11 定案，結論見下。

## Motivation

Widget 天生是效期類 app 的核心價值：使用者不必開啟 app 就能知道「有沒有東西快壞了」。這正是本 app 想促成的行為——而目前它只在每天 09:00 的通知裡出現一次（見 `notification`），其餘時間完全被動。

作為免費功能，它同時是下載誘因：商店截圖能呈現 Widget，對「效期管理」這個需求的說服力高於單純的清單畫面。

本 change 取代原本 GitHub issue #7 的「Pro 進階功能包」構想。該構想把 Widget 與自訂提醒、歷史趨勢、分類標籤綁成一個付費包，現已捨棄——Widget 改為完全免費且獨立，其餘三項不在本 change 範圍，亦無既定計畫。

## 已確定的部分

- **完全免費**，不與 `iap-remove-ads` 的 entitlement 有任何關聯。
- **刻意簡單**：顯示效期概況，比照首頁的環形圖與數量。
- **不含提醒功能**——提醒維持由 `notification` 在 app 內排程，Widget 不參與。
- 效期狀態在 Widget 端依 `food-item` 的既有規則計算（`ExpiryStatus` 不持久化，讀取時算）。
- **Widget 與主 app 共用同一份 SwiftData store**，透過 App Group container 達成。不採用「app 寫摘要檔、Widget 讀摘要」的替代方案——該方案的唯一優勢是規避手動遷移，而查證後手動遷移並不需要（見下）。

## 技術前提（2026-08-11 查證結論）

### 一、App Group 的資料遷移由 SwiftData 自動處理，但觸發條件很脆弱

Widget 是獨立的 process，無法存取 app 自身容器內的 SwiftData store，兩者必須共用 App Group container。目前尚未設定：

- `Sources/App/FoodEntropy.entitlements` 無 App Group 宣告。
- `SwiftDataManager.init` 未指定容器位置。

**原本的顧慮是「改用 App Group container 等同改變 store 檔案位置，需要一次高風險的手動遷移」。查證後這個顧慮不成立**：Apple 官方文件對 `ModelConfiguration.GroupContainer` 載明，當 app 從沒有 App Group container 的版本演進到有的版本時，SwiftData 會自行把既有 store 複製進 App Group container。

關鍵在於**這個自動複製掛在 `groupContainer` 的隱含 `.automatic` 偵測上**。三份公開資料在此分歧，而分歧的成因正是這一點：

| 做法 | 既有資料 |
|---|---|
| 只加 App Group entitlement，完全不碰 `ModelConfiguration` | 自動複製過去，資料保留 |
| 指定 `ModelConfiguration(url:)` | 開出空 store，既有資料讀不到 |
| 指定具名 configuration 加 `groupContainer` identifier | 開出空 store，既有資料讀不到 |

後兩者是網路教學與論壇回報的常見寫法，也是「自動複製無效」這類回報的來源——它們並非踩到 framework 缺陷，而是明確指定了目標，因而繞過自動偵測。`ModelConfiguration` 的第一個參數為 configuration name，會決定 store 檔名；指定它等同開一個不同的檔案。

**因此本 change 的實作約束是：加入 App Group entitlement 之後，不得為此在 `ModelConfiguration` 上指定 configuration name、`url` 或 `groupContainer` identifier。** 現行 `SwiftDataManager.init` 只傳 `cloudKitDatabase`，正好符合此條件，預期無需修改。

仍需以實測確認的兩點：

1. **自動複製失敗時的降級行為。** 公開資料未描述失敗路徑。`persistence` 有三層降級（見 `app-shell`），需確認複製失敗時是退回既有位置繼續運作，而非開出空的新 store——後者對使用者等同資料遺失，且 iCloud 同步預設關閉（見 `icloud-sync`），多數使用者無雲端可回復。
2. **與 CloudKit 併用時的行為。** 現行設定同時帶 `cloudKitDatabase`，而 `groupContainer` 為隱含的 `.automatic`，兩者併用的互動無公開文件說明。

由於正確做法的特徵是「不寫任何指定容器的程式碼」，實作端沒有可供靜態檢查的痕跡，只能以升級情境實測驗證。此實測為動工前置，見 Impact。

### 二、Timeline 需在跨日時刷新

`ExpiryStatus` 是日期的函式（見 `food-item`）——同一筆資料在午夜過後就換桶。Widget 的 timeline 因此不能只在資料變動時更新，必須至少在每日起始重新計算，否則會顯示過期的分桶結果。資料變動時（新增／標記／刪除）亦需由 app 主動要求重新載入。

### 三、Widget 端同樣不得外洩 @Model

`TimelineEntry` 須攜帶 Domain Model 而非 `@Model` 物件。除了憲章的分層規定之外，`TimelineEntry` 會跨 process 傳遞，持有 context-bound 的持久化物件本身不安全。`toDomain()` 已存在，Widget 端沿用即可。

Widget 端建立容器失敗時亦不得以 `fatalError` 終止——Widget 崩潰對使用者是一塊空白磚，比顯示佔位內容更糟。

## UI（2026-08-11 定案）

**與首頁「現況」區塊完全相同的版面，且共用同一份實作。** 這不是「做得像」，而是把首頁那塊抽成共用元件，Widget 與首頁各自引用——如此兩者不會隨時間各自漂移，改配色、文案或無障礙處理都只改一次。

| 項目 | 決定 |
|---|---|
| 尺寸 | 僅 `systemMedium`。首頁該區塊是 120 點的甜甜圈加三行 legend，與中尺寸的版面帶吻合；小尺寸放不下，硬塞就得砍 legend，那已非「相同版面」。 |
| 內容 | 甜甜圈（三桶佔比 + 中心總數）、legend 三行（色點、桶名、數量）、前瞻金額行（有金額才渲染），與首頁一致。 |
| 鎖定畫面 | 不納入。accessory 系列為單色渲染，無法呈現三桶配色，需要另一套設計，不屬於「相同版面」。 |
| 空狀態 | 沿用首頁既有文案，無需新增字串。 |
| 點擊 | 開啟 app 首頁，與 Non-Goals 一致。 |

抽出時的兩處語境差異——這是 Widget 沒有 `List` 語境所致，不是設計上的妥協：

1. 共用元件只涵蓋內容本身，`Section` 容器與「現況」標題留在首頁。
2. 前瞻金額行為條件顯示，首頁在 `List` 中可自然撐開，Widget 高度固定，需預留該行空間以免有無金額時版面跳動。

## Non-Goals

- 不做任何提醒或通知功能。
- 不做付費分層——Widget 完全免費。
- 不做互動式操作（標記已使用等）；點擊行為僅限開啟 app，除非後續與 `add-app-intents` 整合。
- 不涵蓋原 issue #7 的自訂提醒、歷史趨勢圖、分類標籤三項。
- 不改變既有的通知排程行為。
- **不採用「app 寫摘要檔、Widget 讀摘要」的資料傳遞方式。** 該方案能完全規避 store 位置變更，但代價是資料在 app 未開啟時可能過期，且擋死未來的互動式 Widget；既然自動複製使遷移風險降至可驗證的範圍，此方案已無必要。

## Capabilities

### New Capabilities

- `widget`：Widget 的資料來源、顯示內容、timeline 更新策略、Domain Model 邊界在 extension 端的延續，以及「與 app 內畫面共用同一份呈現實作」這項約束。

### Modified Capabilities

- `persistence`：store 位置因 App Group entitlement 而改變，並新增「不得明確指定容器位置或名稱」這條實作約束——指定即會關閉 SwiftData 的自動複製，導致既有資料讀不到。原先預期的「手動遷移要求」經查證後不需要，不列入。
- `app-shell`：新增 Widget extension target，`project.yml` 需宣告該 target 與 App Group entitlement；MVVMC 資料夾慣例需涵蓋 extension 的擺放位置，以及「同時被 app 與 extension 使用的檔案」該放在哪裡。

## Impact

- Affected specs: 新 `widget`；`persistence`、`app-shell` 需修改
- Affected code:
  - New:
    - Widget extension target（含 `TimelineProvider`、Widget view、`TimelineEntry`）
    - `Sources/Core/Components/StatusChartView.swift`——由首頁「現況」區塊抽出的共用呈現元件，app 與 extension 兩個 target 皆納入
  - Modified:
    - `Sources/Features/Home/HomeView.swift`——改為引用共用元件，`Section` 容器與標題留在此處
    - `Sources/App/FoodEntropy.entitlements`
    - `project.yml`
  - Reference: `Sources/Core/Persistence/SwiftDataManager.swift`（預期不需修改，但實測後才能確認）
- 動工前置（**先於任何實作**）：以升級情境實測自動複製——取已有資料的 v1.1.0 build，直接升級為加了 App Group entitlement 的 build，確認資料仍在；iCloud 同步開啟與關閉各測一次。此實測結果決定本 change 能否進行，未通過則需重新評估資料傳遞方式。
- 外部作業：Apple Developer 後台需建立 App Group identifier
- 排程：未定
