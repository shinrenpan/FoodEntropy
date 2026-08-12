## Summary

把 1.2.0 上架過程中重複踩到的三個工具鏈陷阱，寫成 `app-store-listing` 的 requirements。

## Motivation

1.2.0 的上傳花掉的時間絕大多數不在建置本身，而在三個與程式碼無關的地方。其中一個是**第二次**踩到：

**一、Xcode export 因 rsync 版本而失敗，錯誤訊息完全不指向原因。** Xcode 在 export 階段呼叫 `rsync` 複製產物，若 PATH 中的 Homebrew 版本排在系統版之前，參數不相容會使流程中止，而 Xcode 只顯示「Copy failed」——沒有檔名、沒有指令、沒有 rsync 字樣。1.1.0 上傳時踩過一次，當時的解法（改用系統 rsync）沒有留下記錄，1.2.0 又重踩一次。

**二、App ID 新增 capability 後，既有的 distribution profile 不會自動更新。** 為了 Widget 而在 App ID 加上 App Groups 之後，實機測試一切正常——因為 development profile 由 Xcode 自動重建。但 distribution profile 是 1.1.0 時產生的，不含該 capability，export 才會失敗；Widget 的 bundle identifier 更是從未有過 distribution profile。

以命令列搭配 App Store Connect API key 加上自動更新選項亦無法解決：該 key 沒有 cloud signing 權限，回報 `Cloud signing permission error`。最終必須改由 Xcode GUI 執行 distribute，因為它使用開發者本人的 Apple ID 而非 API key。

**三、示範資料放置數日後全數過期，截圖會拍到一片紅。** 示範食材的到期日是以「灌入當下」為基準計算的相對日期。8 月 8 日灌入的資料到 8 月 12 日截圖時，五筆中有四筆已過期，Widget 呈現幾乎全紅、且因近期到期歸零而使金額行整行不渲染——那正是要展示的賣點。

三者的共同點：**都不會在建置階段報錯，也都不是程式碼問題**。沒有記錄的話，下一次發布只會重新查一遍。

## Proposed Solution

於 `app-store-listing` 新增三條 requirement，各自描述「什麼情況下會失敗」與「失敗時看起來像什麼」——後者尤其重要，因為這三個問題的表象都與成因無關：

- 上傳前確認 `rsync` 解析到系統版本；「Copy failed」應被視為此問題的徵兆而非字面意義。
- 變更 App ID 的 capability 後，distribution profile 必須重新產生，且該操作需要開發者帳號本身的權限，API key 不足。
- 產生商店截圖前必須重灌示範資料，因其日期為相對值。

## Non-Goals

- 不自動化上傳流程。三個問題中有兩個必須由 Xcode GUI 或人工判斷處理，自動化只會把失敗推到更難診斷的地方。
- 不改變示範資料的產生方式（例如改為絕對日期）。相對日期正是它在預覽與測試情境下有用的原因；要修的是「截圖前重灌」這道程序，不是資料本身。
- 不申請或調整 App Store Connect API key 的權限。cloud signing 權限涉及憑證管理，超出本 change 範圍；已確認 Xcode GUI 可完成，無需為此擴權。
- 不涵蓋送審後的流程（審查回應、發布時機）。

## Alternatives Considered

**寫進 `CLAUDE.md` 而非 spec。** 已否決——`CLAUDE.md` 是給 AI 的常駐指示，而這三件事只在發布時才相關，放在那裡會稀釋日常開發的指示密度。`app-store-listing` 本就是「規範對象不在 repo 內」的 capability，這三個工具鏈事實正屬於它。

**只記在 change 的 tasks 裡。** 已否決——tasks 隨 change 封存，下次發布不會有人回頭翻閱已封存的 change。requirement 才會被 `/spectra-ask` 與後續的 spec 閱讀涵蓋。

## Impact

- Affected specs: `app-store-listing`
- Affected code:（無。本 change 只新增 spec requirements，不動任何原始碼或設定檔）
- 適用時機：每次發布新版本至 App Store 時。
