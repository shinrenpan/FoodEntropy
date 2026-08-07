## Context

iCloud 同步在本專案是一個布林偏好，而不是一套同步實作：實際的同步工作全由 `NSPersistentCloudKitContainer` 承擔，app 要做的只有「啟動時決定 `ModelConfiguration` 掛不掛 `cloudKitDatabase`」。這個極簡的做法之所以可行，前提是 `persistence` 的 schema 從第一天就是 CloudKit 形狀——否則切換就需要 schema migration，整個設計會立刻崩解。

原始產品規格（`specs/archive/Spec.md`）寫的是「無感自動同步」。v1.0.0 推翻了它。

## Goals / Non-Goals

**Goals:**
- 記錄 opt-in、預設關的理由，及其與「無 Onboarding」的關係。
- 記錄「下次啟動生效」而非熱切換的理由。
- 記錄開關兩個方向的資料語意，特別是關閉不刪雲端。
- 記錄圖片為何也在同步範圍內。

**Non-Goals:**
- 無行為變更。
- 不涵蓋 `persistence` 的 schema 約束、`app-shell` 的降級、`settings-ui` 的版面。

## Decisions

### opt-in、預設關閉，推翻原始規格的「無感自動同步」

同步偏好存於 `UserDefaults`，預設 `false`。理由：食材紀錄含使用者的照片，把它們上傳到雲端（即使是使用者自己的私有 iCloud 資料庫）也應該是使用者主動選擇的結果，而不是預設行為。這同時解決了一個產品問題：預設關閉意味著「使用者打開開關」本身就構成同意，因此不需要首次啟動的同意詢問，app 得以維持沒有 Onboarding 的直接體驗。考慮過的替代方案：預設開啟並在首次啟動詢問——否決，那需要一個 Onboarding 步驟，且把「不想同步」的使用者放在必須主動拒絕的位置。

### 變更後於下次啟動生效，不做執行期熱切換

切換開關只寫入偏好並提示需要重新啟動；`ModelContainer` 在 `SceneDelegate` 啟動時依偏好建立一次，之後不再變動。理由：熱切換意味著在執行期丟棄現有的 `ModelContainer` 與 `mainContext`、建立新的，並讓所有持有舊 context 的物件同步換手。SwiftData 沒有為此提供安全的路徑，而失敗的代價是資料遺失。相對地，「重開 app」對使用者是一個他們完全理解、且一定會成功的操作。考慮過的替代方案：實作熱切換以避免提示重啟——否決，風險與收益完全不成比例。

### 開關兩個方向指向同一個本機 store

開啟與關閉同步時，`ModelConfiguration` 只差在 `cloudKitDatabase` 是 `.automatic` 還是 `.none`，store 檔案位置不變。理由：這是雙向切換能無痛的關鍵——本機資料從頭到尾是同一份，不需要在切換時搬移任何東西。搭配恆為 CloudKit-safe 的 schema（見 `persistence`），切換不觸發任何 migration。

### 開啟同步時，既有本機資料自動上傳

關 → 開之後，底層 `NSPersistentCloudKitContainer` 自動把既有本機資料鏡射到 CloudKit，app 不需要任何自訂的搬資料程式碼。理由：這符合使用者按下開關時的期待——「我要備份我的資料」指的是全部資料，不只是之後新增的。上傳是背景非同步進行，不會即時完成。

### 關閉同步時，雲端副本保留不動

開 → 關之後，本機資料續用，CloudKit 上的既有副本不刪除。理由：「關閉同步」的語意是停止推送與拉取，不是「刪除我的備份」。使用者若之後再打開，資料會自動合併接回；若在關閉時清除雲端，這個往返就變成不可逆的資料破壞。考慮過的替代方案：關閉時提示是否一併刪除雲端資料——否決，那是一個危險且罕用的操作，不該擺在一個日常開關旁邊。

### 圖片隨同步一併處理，不另存 Documents

照片以 `@Attribute(.externalStorage)` 存在 SwiftData 內（見 `persistence`），因此自然落在同步範圍內。理由：原始規格考慮過把圖片存 Documents 目錄，但那些檔案不會被 CloudKit 同步，會造成「資料同步了、照片沒跟上」的破碎狀態。

## Implementation Contract

**Behavior (observable):**
- 全新安裝的 app，同步開關為關閉。
- 切換開關後畫面提示需要重新啟動才會生效，且此次啟動的同步行為不變。
- 從關閉切到開啟並重啟後，先前建立的食材與照片會逐步出現在同一 Apple ID 的其他裝置上。
- 從開啟切到關閉並重啟後，本機資料完整保留，且其他裝置上的既有資料不會消失。
- 再次開啟同步並重啟後，先前的雲端資料與本機資料合併。

**Interface / data shape:**
- 偏好鍵集中宣告於 `AppPreferenceKey.iCloudSyncEnabled`，型別為 `Bool`，未設定時 `UserDefaults.bool(forKey:)` 回傳 `false`。
- `SwiftDataManager.init(cloudKitEnabled:inMemory:)`：`cloudKitEnabled` 決定 `ModelConfiguration(cloudKitDatabase:)` 為 `.automatic` 或 `.none`。
- 啟動時由 `SceneDelegate` 讀取偏好並傳入。
- 設定畫面切換時寫入偏好並設定重啟提示旗標。

**Acceptance criteria:**
- `grep -rn "iCloudSyncEnabled" Sources` 只透過 `AppPreferenceKey` 常數存取，無字面字串散落。
- `ModelConfiguration(cloudKitDatabase:)` 僅在 `SwiftDataManager.init` 內出現一處。
- 切換開關的處理不重建 `ModelContainer`。

**Scope boundaries:**
- In scope：偏好的儲存與預設、生效時機、雙向切換的資料語意、圖片同步範圍。
- Out of scope：schema 的 CloudKit-safe 約束（`persistence`）、容器建立失敗的降級（`app-shell`）、設定列的版面與文案（`settings-ui`）、CloudKit Production schema 的部署。

## Risks / Trade-offs

- [需要重新啟動才生效] → 使用者切換後可能立刻檢查其他裝置、發現沒動靜而認為功能故障。以重啟提示緩解，但提示本身也可能被忽略。接受此代價以換取不在執行期抽換 store。
- [上傳是背景非同步] → 開啟同步後資料不會立刻出現在其他裝置，且 app 內沒有任何同步進度指示。使用者無從得知是否完成，也無法察覺同步失敗。
- [關閉同步不刪雲端] → 使用者若以為「關掉就等於刪除我在雲端的資料」，實際上並非如此。這是刻意的取捨，但與部分使用者的隱私預期可能相反；若未來要提供刪除入口，應是獨立且有明確警告的操作。
- [沒有任何同步狀態的可見性] → 目前 app 完全不顯示同步是否正常運作。CloudKit 失敗時（配額滿、未登入 iCloud）使用者只會看到資料沒同步，沒有任何提示。
