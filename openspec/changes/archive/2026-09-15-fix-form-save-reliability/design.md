## Context

`FoodFormViewModel` 的儲存路徑是 add / edit 共用的唯一寫入入口，流程由 `food-form-ui` 的「Saving writes, then requests permission, then reconciles reminders, then closes」規範：寫入 → 請求通知權限 → 重建通知排程 → 關閉表單。該 requirement 只描述成功路徑，因此下列兩件事目前既沒有規範、也沒有實作：

- **儲存進行中的重複觸發**。儲存動作的 guard 只有 `state.isSaveEnabled`（名稱去頭尾空白後非空），該條件在儲存期間恆為 true，`FoodFormView` 的儲存鈕綁的也是同一個條件。寫入本身同步完成，但後續的請求權限與重建排程都是 `await`：前者是一次與通知 daemon 的行程間往返，後者對每個 active 食材循序註冊一則通知（`notification` 的排程上限為 60 則）。表單在整段期間留在畫面上且鈕可按。
- **寫入失敗**。`add-app-intents` 的資料層改動已讓寫入失敗丟給呼叫端，但表單以 `try?` 接住後丟棄，接著照成功路徑走完並關閉。

`persistence` 現行的免責條款是：「A caller that merely presents data MAY ignore the failure, because the unchanged interface already tells the user nothing happened.」其理由——畫面沒變即等於告知失敗——對首頁列操作成立，對表單不成立：表單關閉是這個 app 表示成功的訊號，失敗時關閉等同回報成功。

本專案的 ViewModel 測試哲學（`mvvmc-testing`）是透過 `doAction` 注入結果而非以 protocol / mock class 替換相依。`SwiftDataManager` 是具體型別、無法在測試中令其寫入失敗，因此失敗路徑必須能以一個 action 直接驅動。

## Goals / Non-Goals

**Goals:**

- 儲存進行中不可能產生第二筆寫入。
- 寫入失敗時使用者一定知道，且輸入不遺失、可原地重試。
- 失敗路徑可在單元測試中直接驅動，不需要令真實儲存失敗。
- `food-form-ui` 與 `persistence` 的 requirement 涵蓋失敗路徑，不再只描述成功路徑。

**Non-Goals:**

- **不改首頁列操作的靜默行為**（已使用／丟棄／刪除／延長／清除歷史）。理由見〈首頁列操作維持靜默〉。
- 不做重試、佇列、離線暫存。失敗就是失敗，由使用者決定要不要再按一次。
- 不改資料層：`SwiftDataManager` 的方法簽章、錯誤型別、三層降級一律不動。
- 不改助理／捷徑路徑。該路徑的錯誤處理在 `app-intents` 已完成且行為正確。
- 不新增任何功能（包含到期前提醒）。
- 不為此change加入 VoiceOver 驗收（見專案的 out-of-scope 宣告）。

## Decisions

### 儲存進行中以 State 欄位表達，並同時關閉儲存鈕

在 `FoodFormViewModel.State` 新增一個布林欄位表示「儲存進行中」。儲存動作在進入時檢查該欄位，已在進行中則直接返回；成功或失敗結束時清回 false。`FoodFormView` 的儲存鈕失效條件從「名稱為空」改為「名稱為空**或**儲存進行中」。

兩層都要做：State 的 guard 是正確性保證（鍵盤快捷、輔助技術、或 SwiftUI 在鈕失效生效前已派發的觸發都繞得過視覺狀態），鈕失效則是讓使用者看得出來系統正在忙。同專案的購買流程（`iap-remove-ads`）用的是同一種 in-flight 布林，此處刻意比照而非另創機制。

不採用「在儲存開始時就關閉表單」的替代方案——那會讓失敗無處可報，正是本 change 要修的問題。

`isSaveEnabled` 的語意維持不變（只看名稱），因為 `food-form-ui` 有獨立的 requirement 規範「Saving requires a name that is not blank」；把進行中狀態混進同一個條件會讓那條 requirement 的對應物變得不精確。

### 寫入失敗以 DataResponse action 回流，使失敗路徑可測

儲存改為捕捉資料層丟出的錯誤，並把結果以一個新的 response action 送回 `doAction`：成功一種、失敗一種。關閉表單與顯示失敗警示都發生在處理該 response 的地方，而非寫入的地方。

這麼做的理由是可測性：`SwiftDataManager` 是具體型別，測試無法令其寫入失敗。把失敗表達成 action 之後，測試可以直接送失敗 response 並斷言「表單未關閉、警示已顯示、進行中狀態已清除」，完全不需要 protocol 或 mock class——這正是 `mvvmc-testing` 規定的做法。

替代方案是讓測試注入一個會丟錯的 manager（需要把 `SwiftDataManager` 抽成 protocol）。否決：那是整個專案都沒有採用的模式，為一條失敗路徑引入會擴散到所有 ViewModel。

### 寫入失敗時停在表單，且不執行後續兩步

失敗時：不關閉表單、不請求通知權限、不重建通知排程，改為顯示一則告知儲存失敗的警示。使用者已輸入的內容原樣留在表單上。

不請求權限與不重建排程不是省事，是語意正確：這兩步的對象是「剛寫進去的那筆」，而它不存在。首次儲存就失敗時跳出通知權限彈窗尤其不合理——使用者會在一個什麼都沒發生的操作後被要求授權。

警示只有一個確認鈕，不提供「重試」鈕：重試就是再按一次儲存，多一個鈕只是同一個動作的第二個入口。

### 首頁列操作維持靜默

首頁的五個寫入路徑（已使用、丟棄、刪除、延長效期、清除歷史）維持現行的忽略失敗行為，本 change 不動。

理由是 `persistence` 免責條款的前提在首頁確實成立：每個列操作結束後都會重新讀取並重繪清單，寫入失敗時該列仍在原位、統計數字不變，畫面本身就說明了什麼都沒發生。使用者的下一步（再按一次）與顯示錯誤後的下一步相同，且沒有任何資料遺失風險。

表單不同之處只有一個，但那一個是決定性的：它在成功時**關閉自己**。關閉是成功訊號，失敗時關閉就是謊報。

這不是「先修一半」，是兩者性質不同。若日後首頁改成操作後有任何形式的成功回饋（吐司、動畫、觸覺），前提即失效，屆時再一併處理。

### persistence 的免責條件收斂為「失敗後畫面不變」

`persistence` 的「A caller that merely presents data MAY ignore the failure」措辭不精確：表單也只是呈現資料，卻不適用。把條件改寫成依據**失敗後畫面是否維持不變**——維持不變者可忽略，會在成功時收起或切換自身畫面者不得忽略，必須讓使用者知道。

同時補上對應的 scenario，讓「表單關閉即成功訊號」這件事寫進契約，而不是留在程式碼註解裡。

## Implementation Contract

**行為（使用者可觀察）**

1. 使用者點下儲存後，在儲存完成前儲存鈕呈現失效；此期間再次觸發儲存不會產生第二筆紀錄，也不會第二次請求權限或重建排程。
2. 寫入成功時，行為與現況完全相同：寫入 → 請求通知權限（僅在尚未決定時）→ 以當前 active 重建排程 → 關閉表單。
3. 寫入失敗時，表單留在畫面上，顯示一則說明儲存失敗、請重試的警示；名稱、日期、照片、價格維持使用者輸入的值；不請求通知權限；不重建排程；不關閉表單。關閉警示後可直接再次儲存。
4. 失敗後使用者選擇返回時，沿用既有的未儲存變更確認流程，不新增額外提示。

**介面／資料形狀**

- `FoodFormViewModel.State` 新增兩個布林欄位：一個表示儲存進行中、一個驅動失敗警示的顯示。兩者皆有預設值 false，`State` 維持 `Equatable, Sendable`。
- `FoodFormViewModel.Action` 新增 `dataResponse` case，其關聯的 response enum 至少含「儲存成功」與「儲存失敗」兩種。`Action` 與新 enum 維持 `Sendable`。
- `isSaveEnabled` 的定義不變，仍只反映名稱是否非空。
- 儲存鈕的失效條件改為同時考慮名稱與儲存進行中。
- `SwiftDataManager` 的公開介面不變。

**失敗模式**

- 表單寫入失敗：向使用者顯示警示（本 change 的重點）。
- 讀取失敗：維持現況，回空集合不報錯。
- 首頁列操作寫入失敗：維持現況，刻意靜默。
- DEBUG build 的 assertion 維持現況，在資料層觸發。

**字串**

新增的使用者可見字串以英文字面值直接寫在 SwiftUI 的 `alert` / `Button` 內（不得經由變數傳遞 `LocalizedStringKey`），由 build 抽取進 String Catalog，再補 `zh-Hant` 翻譯。驗收時 stale 數與缺翻譯數皆須為 0。

**驗收標準**

- `FoodFormViewModelTests` 新增測試涵蓋：進行中再次觸發儲存不會產生第二筆紀錄；送入儲存失敗 response 後表單未關閉、失敗警示為顯示狀態、進行中狀態已清除；送入儲存成功 response 後表單關閉。
- 既有 `FoodFormViewModelTests` 全數維持通過（成功路徑行為不得改變）。
- 完整測試套件通過。
- `spectra validate fix-form-save-reliability` 通過。

**範圍邊界**

- 範圍內：`FoodForm` 這個 feature 的三個檔案、其測試、String Catalog，以及 `food-form-ui` 與 `persistence` 兩份 spec 的 delta。
- 範圍外：首頁、設定頁、資料層、助理／捷徑路徑、Widget、通知服務本身。

## Risks / Trade-offs

- **[失敗警示極難在真實裝置上重現]** → 寫入失敗需要磁碟滿或 CloudKit 衝突，無法按需觸發。以 action 驅動的單元測試涵蓋失敗路徑的狀態轉移；警示的實際外觀依賴既有的 SwiftUI alert 機制（同檔案的放棄變更確認已在用），風險低。
- **[儲存進行中鈕失效可能被誤認為卡住]** → 正常情況下這段時間只有數十毫秒到數百毫秒，使用者不會察覺；排程上限 60 則的極端情況下略長，但那本來就是實際在忙。不加轉圈指示器，避免為極短暫的狀態引入視覺跳動。
- **[首頁維持靜默會讓兩處行為不一致]** → 這是刻意的，且已寫進 `persistence` 的 requirement 與 scenario，不是未記錄的差異。判準明確：畫面在失敗後是否維持不變。
- **[新增 State 欄位可能影響未儲存變更的判斷]** → 未儲存變更的比對採用獨立的 snapshot 結構，只含使用者可編輯的欄位；新增的兩個欄位屬 UI 狀態，不得加入該 snapshot，否則顯示過警示就會被當成有未儲存變更。
