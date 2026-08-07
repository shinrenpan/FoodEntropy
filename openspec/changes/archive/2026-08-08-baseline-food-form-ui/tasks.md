## 1. Baseline 文件化

- [x] 1.1 從 `FoodFormMode`、`FoodFormViewModel.init` 的模式分流與 `navigationTitle` 寫出 requirement「One form serves both adding and editing」；驗證：`init` 的 `.add` 分支設購買日 `.now`、到期日 `.now + 3 天`，`.edit` 分支帶入 item 各欄位；`navigationTitle` 兩分支皆以 `String(localized:)` 取得。
- [x] 1.2 從 `State.isSaveEnabled`、`save()` 的 trimming 與 `saveDidTap` 的 guard 寫出 requirement「Saving requires a name that is not blank」；驗證：`isSaveEnabled` 以 `trimmingCharacters(in: .whitespacesAndNewlines).isEmpty` 判斷；`save()` 寫入前先 trim；`saveDidTap` 以 `guard state.isSaveEnabled else { return }` 開頭；`FoodFormView` 的儲存鈕帶 `.disabled(!viewModel.state.isSaveEnabled)`。
- [x] 1.3 從到期日 DatePicker 的範圍與 `purchaseDateChanged` 的頂推寫出 requirement「The expiry date can never precede the purchase date」；驗證：`FoodFormView.swift:29` 的 DatePicker 帶 `in: viewModel.state.purchaseDate...`；`purchaseDateChanged` 在 `date > state.expiryDate` 時把 `expiryDate` 設為該日。
- [x] 1.4 從 `Snapshot`、`isDirty` 與 `dismissDidTap` / `discardConfirmed` / `discardCancelled` 寫出 requirement「Leaving with unsaved changes asks first, and leaving unchanged does not」；驗證：`Snapshot` 僅含 `name` / `purchaseDate` / `expiryDate` / `imageData` 四欄，不含 `showDiscardConfirm`；`isDirty` 以當前 state 重建 Snapshot 與 `original` 比對；`dismissDidTap` 依 `isDirty` 分流。
- [x] 1.5 從 `FoodFormView` 的 `navigationBarBackButtonHidden(true)` 與自訂取消鈕寫出 requirement「The form provides its own back control」；驗證：第 65 行隱藏系統返回鈕，第 67–71 行的 `.cancellationAction` 按鈕發出 `dismissDidTap`。
- [x] 1.6 從 `confirmationDialog` 的選項組成與大圖預覽寫出 requirement「Photos are chosen from a menu and removed only when one exists」；驗證：選單含「拍照」「從相簿選」「取消」，「移除照片」以有照片為條件顯示（第 42–46 行）；有照片時顯示 `maxHeight: 260` 的大圖預覽。
- [x] 1.7 從 `save()` 的呼叫順序寫出 requirement「Saving writes, then requests permission, then reconciles reminders, then closes」；驗證：`save()` 內順序為 `manager.create/update` → `requestAuthorizationIfNeeded()` → `reconcile(...)`；`saveDidTap` 在 `await save()` 之後才 `onRoute?(.close)`。
- [x] 1.8 從 `ViewAction` 列舉的組成寫出 requirement「The form edits fields only」；驗證：列舉中無任何刪除／標記已使用／標記丟棄／延長效期的 case，且 `FoodFormViewModel` 未呼叫 `markConsumed` / `markWasted` / `delete`。

## 2. 收尾

- [x] 2.1 執行 `spectra validate baseline-food-form-ui`；驗證：指令回傳成功、無 error。
- [x] 2.2 archive 後補上 `openspec/specs/food-form-ui/spec.md` 的 `## Purpose` 段；驗證：`grep -c "TBD" openspec/specs/food-form-ui/spec.md` 為 0。
- [x] 2.3 ~~實機確認邊緣滑動返回是否繞過放棄確認~~ → **結案：確認為刻意設計**。系統層手勢的離開語意由 iOS 定義、使用者已知其結果，故不攔截；只有 app 自己的返回控制項走 dirty 確認。已由 `amend-food-form-back-gesture` 修正規格描述（該風險條目措辭已不適用）。
