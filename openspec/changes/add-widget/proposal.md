## Summary

加入一個**免費**的 Widget，在主畫面／鎖定畫面一眼顯示食材效期概況（環形圖 + 數量，比照首頁）。定位是下載誘因與日常曝光，刻意保持簡單：不含提醒功能、不做付費分層、不做互動操作。**UI 細節待討論**；另有兩項技術前提會影響實作成本，見下。

## Motivation

Widget 天生是效期類 app 的核心價值：使用者不必開啟 app 就能知道「有沒有東西快壞了」。這正是本 app 想促成的行為——而目前它只在每天 09:00 的通知裡出現一次（見 `notification`），其餘時間完全被動。

作為免費功能，它同時是下載誘因：商店截圖能呈現 Widget，對「效期管理」這個需求的說服力高於單純的清單畫面。

本 change 取代原本 GitHub issue #7 的「Pro 進階功能包」構想。該構想把 Widget 與自訂提醒、歷史趨勢、分類標籤綁成一個付費包，現已捨棄——Widget 改為完全免費且獨立，其餘三項不在本 change 範圍，亦無既定計畫。

## 已確定的部分

- **完全免費**，不與 `iap-remove-ads` 的 entitlement 有任何關聯。
- **刻意簡單**：顯示效期概況，比照首頁的環形圖與數量。
- **不含提醒功能**——提醒維持由 `notification` 在 app 內排程，Widget 不參與。
- 效期狀態在 Widget 端依 `food-item` 的既有規則計算（`ExpiryStatus` 不持久化，讀取時算）。

## 技術前提（影響「簡單」的成本估計）

### 一、需要 App Group，且涉及既有使用者的資料遷移

Widget 是獨立的 process，無法存取 app 自身容器內的 SwiftData store。要讀取同一份資料，兩者必須共用 App Group container——`ModelConfiguration` 需指定 group container，而目前並未設定：

- `Sources/App/FoodEntropy.entitlements` 無 App Group 宣告。
- `SwiftDataManager.init` 使用預設容器（`URL.applicationSupportDirectory`）。

改用 App Group container 等同**改變 store 的檔案位置**。v1.0.0 已上架，既有使用者的資料位在舊位置，因此需要一次遷移，且必須考慮：

- iCloud 同步預設關閉（見 `icloud-sync`），多數使用者只有本機資料——遷移失敗即為資料遺失，沒有雲端可回復。
- 遷移只能發生一次，且要能容忍中斷（App 在遷移途中被終止）。
- 與 `persistence` 的三層降級（見 `app-shell`）如何互動：遷移失敗時該降級到舊位置繼續運作，而非降級到空的新位置。

**這是本 change 最大的風險，也是「簡單的 Widget」實際上不簡單的原因。** 實作前需確認 SwiftData 對 group container 遷移的官方支援程度，以及是否有比手動搬檔更安全的路徑。

### 二、Timeline 需在跨日時刷新

`ExpiryStatus` 是日期的函式（見 `food-item`）——同一筆資料在午夜過後就換桶。Widget 的 timeline 因此不能只在資料變動時更新，必須至少在每日起始重新計算，否則會顯示過期的分桶結果。資料變動時（新增／標記／刪除）亦需主動要求重新載入。

## 待討論：UI

初步方向是比照首頁的環形圖 + 中心總數，但以下未定：

1. **支援哪些尺寸**——小尺寸放得下環形圖嗎，或小尺寸改為純數字？
2. **顯示哪些資訊**——三桶全顯示，或只顯示最急迫的（已過期 + 3 天內）？
3. **鎖定畫面 Widget** 是否納入（尺寸與配色限制更嚴格）？
4. **無資料時顯示什麼**——沿用首頁的空狀態文字，或改為引導新增的提示？
5. **點擊行為**——開啟 app 首頁即可，或未來與 `add-app-intents` 整合為可直接操作的互動 Widget（後者需先確認 App Intents 的範圍）。

## Non-Goals

- 不做任何提醒或通知功能。
- 不做付費分層——Widget 完全免費。
- 不做互動式操作（標記已使用等）；點擊行為僅限開啟 app，除非後續與 `add-app-intents` 整合。
- 不涵蓋原 issue #7 的自訂提醒、歷史趨勢圖、分類標籤三項。
- 不改變既有的通知排程行為。

## Capabilities

### New Capabilities

- `widget`：Widget 的資料來源、顯示內容、timeline 更新策略。delta spec 待 UI 定案後撰寫。

### Modified Capabilities

- `persistence`：store 改用 App Group container，並新增既有資料的一次性遷移要求。
- `app-shell`：新增 Widget extension target，`project.yml` 需宣告該 target 與 App Group entitlement；MVVMC 資料夾慣例需涵蓋 extension 的擺放位置。

## Impact

- Affected specs: 新 `widget`；`persistence`、`app-shell` 需修改
- Affected code:
  - New: Widget extension target（含 `TimelineProvider`、Widget view）
  - Modified: `Sources/Core/Persistence/SwiftDataManager.swift`（group container + 遷移）、`Sources/App/FoodEntropy.entitlements`、`project.yml`
  - Reference: `Sources/Features/Home/HomeView.swift`（環形圖呈現可複用的部分）
- 外部作業：Apple Developer 後台需建立 App Group identifier
- 排程：未定
