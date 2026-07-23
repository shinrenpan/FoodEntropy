# 03 · 食材 Form（新增 / 編輯共用）

> 狀態：✅ 定案
> 上游：`../01-navigation.md`（§4）、`../02-architecture.md`
> 對應：`FoodFormView` + `FoodFormViewModel`（@Observable @MainActor）

新增與編輯共用同一畫面，透過 Router **push** 進入。push 時 **隱藏 tabbar**（`hidesBottomBarWhenPushed = true`）：填寫為聚焦任務，避免中途誤切 Tab、鍵盤彈出時版面更寬。

---

## 模式

```swift
enum Mode: Equatable, Sendable {
    case add
    case edit(FoodItem)   // 帶入既有 Domain Model 預填
}
```

| | add | edit |
|---|---|---|
| 導航標題 | 新增食材 | 編輯食材 |
| 進入點 | 首頁 FAB | 首頁 row 單點 |
| 初值 | 見下方預設 | 帶入該食材現值 |
| 儲存行為 | 新增一筆 | 更新既有筆 |

- Form **只做欄位編輯**；刪除 / 標記已使用 / 標記丟棄 / 延長效期一律回首頁 row 滑動選單處理（本畫面不放這些按鈕）。

---

## 欄位與預設值

| 欄位 | 必填 | add 預設 | 控制項 |
|---|---|---|---|
| 名稱 | ✅ | 空字串 | TextField |
| 購買日期 | ✅ | 今天 | DatePicker（僅日期） |
| 到期日期 | ✅ | 今天 + 3 天 | DatePicker（僅日期） |
| 圖片 | ❌ | 無 → 顯示預設圖示 | 點擊區塊 |

---

## 驗證規則

1. **名稱**：去除頭尾空白後**非空**才有效。無效 → **「儲存」按鈕 disable**（灰掉）。
2. **到期日 ≥ 購買日**：到期日 DatePicker 的**下限綁定購買日**，不允許選更早日期。
   - 若使用者事後把購買日改到比到期日晚，需同步把到期日上推至購買日（或重新夾住），避免出現無效區間。
3. 「儲存」按鈕僅在**名稱有效**時可按（日期恆有值、有預設）。

---

## 圖片操作

- 點圖片區塊 → action sheet：
  - **拍照**（相機）
  - **從相簿選**（PhotosPicker）
  - **移除照片**（僅當已有照片時顯示）
  - 取消
- 選取後於**當下**壓縮：JPEG `0.7`、長邊上限 `1024px`（見 `02-architecture` §3），存為 `Data`。
- 無照片時顯示預設圖示。

---

## 返回 / 放棄

- 有**未儲存變更**（任一欄位相對初值有異動）時按返回 → 跳確認「要放棄變更嗎？」。
- 無任何變更 → 直接 pop，不打擾。

---

## 儲存流程

1. 按「儲存」→ 通過驗證。
2. **首次成功儲存（App 生命週期內第一次）** → 情境式請求**通知權限**（見 `02-architecture` §8）。
3. 寫入：呼叫 manager `create` / `update`。
4. **排程通知**：依到期日 09:00 排程 / 重排（edit 改到期日時取消舊排程再重排；到期日 09:00 已過則不排）。
5. pop 回首頁；首頁 `onAppear` 重撈刷新清單。

---

## State（草案）

```swift
extension FoodFormViewModel {
  struct State: Equatable, Sendable {
    var name: String = ""
    var purchaseDate: Date = .init()          // 由 init 依 mode 給定
    var expiryDate: Date = .init()
    var imageData: Data? = nil
    var showDiscardConfirm: Bool = false
    var showImageSourceSheet: Bool = false

    var isSaveEnabled: Bool {                  // 名稱去空白後非空
      !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
  }
}
```

> dirty 判定（是否有未儲存變更）由 ViewModel 持有初始快照比對，不放進 State 的可比較欄位。

---

## Action（doAction 單一進入點，草案）

```swift
enum Action {
  case onAppear
  case nameChanged(String)
  case purchaseDateChanged(Date)
  case expiryDateChanged(Date)
  case tapImage                    // 開 action sheet
  case pickFromCamera
  case pickFromLibrary
  case imagePicked(Data?)          // 壓縮後結果
  case removeImage
  case tapSave
  case requestDismiss              // 返回：有變更→確認，無變更→pop
  case confirmDiscard              // 確認放棄→pop
}
```

---

## 交由後續處理

- 通知權限**被拒**的引導文案 → 於設定 / 首次請求後的提示，細節見 `settings.md`（待撰）。
- V 層版面（DatePicker 樣式、圖片區塊尺寸）依 `mvvmc-view` 規範於實作階段定。
