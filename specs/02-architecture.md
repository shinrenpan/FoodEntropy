# 02 — 技術架構 / 資料模型

> 狀態：✅ 定案
> 上游：`01-navigation.md`

---

## 1. 分層架構

本專案採 **MVVMC**，資料層在 skill 預設的 State / Domain / DTO 之外，多一層 SwiftData 持久化。因無後端 API，**DTO 角色由 SwiftData `@Model` 扮演**（磁碟來的原始資料，經 `toDomain()` 轉為乾淨 Domain）。

```
SwiftData @Model（持久化 DTO；受 CloudKit 約束）
        ↕
SwiftDataManager（@MainActor）
   ├─ 持有 ModelContainer / ModelContext
   ├─ CRUD：create / fetch / update / delete / markConsumed / markWasted
   └─ 邊界轉換：@Model.toDomain() → 回傳 Domain Model
        ↓
ViewModel（@Observable @MainActor）── 呼叫 manager，映射進 State
        ↓
State（UI 綁定）
        ↓
View（SwiftUI）
```

**鐵則**：
- ViewModel / State **永不持有 `@Model`**，只吃 Domain Model。
- `@Model → toDomain()` 轉換只發生在 **manager 邊界**（呼叫 `@Model` 自身的 `toDomain()`，轉換是它自己的責任）。
- ViewModel 不知道 SwiftData 存在，只跟 manager 要 Domain。

---

## 2. 資料模型

### 2.1 持久化層 `@Model`（CloudKit-safe）

```swift
@Model
final class FoodItemEntity {
    var id: UUID = UUID()
    var name: String = ""
    var purchaseDate: Date = Date()
    var expiryDate: Date = Date()
    var statusRaw: String = "active"          // active / consumed / wasted
    var resolvedAt: Date?                       // 離開 active 的時間（吃掉或丟棄），供未來統計
    @Attribute(.externalStorage) var imageData: Data?   // 壓縮後 JPEG，隨 CloudKit 同步
    var createdAt: Date = Date()

    init(...) { ... }
}
```

**CloudKit 約束（因 iCloud 為可開關同步，model 必須從一開始就相容，否則開同步會 crash）**：
- 所有屬性**必須 optional 或有預設值**。→ 上方每個非 optional 欄位都給預設值。
- **禁用 `@Attribute(.unique)`**。→ `id` 不加唯一約束，唯一性由程式邏輯保證。
- 關聯（若未來新增）必須 optional。

「必填」（名稱 / 購買日 / 到期日）改由 **Form 驗證**把關，而非 DB 約束。

### 2.2 Domain 層（ViewModel 消費）

```swift
// 紀錄狀態（stored，來自 statusRaw）
enum RecordStatus: String, Sendable { case active, consumed, wasted }

// 效期狀態（computed，非儲存；由 expiryDate 比對今天算出）
enum ExpiryStatus: String, Sendable { case fresh, nearExpiry, expired }
```

- `@Model` 提供 `toDomain()` 轉為乾淨的 Domain `FoodItem`（欄位規格待 `03-screens` 細化）。
- **`ExpiryStatus` 不存 DB**，為計算屬性（演算法見 §5，待討論）。

### 2.3 食材離開清單的四種出口

| 操作 | 結果 | `statusRaw` | 留紀錄 |
|---|---|---|---|
| 延長效期 | 仍在清單，改 `expiryDate` | `active` | — |
| 標記已使用 | 移出清單（吃掉） | `consumed` | ✅ |
| 標記丟棄 | 移出清單（過期/壞掉） | `wasted` | ✅ |
| 刪除 | 真的移除（誤加/打錯） | — hard delete | ❌ |

> 首頁 row 因此有 4 個操作，暫先全上，之後視覺過載再滾動收納（如滑動只留常用、其餘進長按選單）。此變更需回頭同步 `01-navigation` §2 的 row 操作。

---

## 3. 圖片儲存

- 儲存於 `@Attribute(.externalStorage) var imageData: Data?`，由 SwiftData 管理 → **隨 CloudKit 同步**（推翻 Spec 的「Documents 路徑」方案，因後者不會被 CloudKit 備份）。
- **壓縮**（在拍照 / 選圖當下處理，不存原圖）：
  - 格式：JPEG（`jpegData(compressionQuality:)`）
  - 品質：`0.7`
  - 縮圖：長邊上限 `1024px`（原圖更大先等比縮小）
  - 目標體積：約 100–300KB / 張
- 數值可日後滾動微調。

---

## 4. 資料流 / 清單刷新

- 無 `@Query`，改由 `@MainActor` 的 SwiftDataManager 提供資料。
- **刷新機制：onAppear 重撈**。首頁自 Form push 返回（pop）觸發 `onAppear` → ViewModel `doAction(.onAppear)` → `manager.fetchActiveFoods()` → 更新 `state.items`。
  - 呼應 `01-navigation` 選用 push：pop 回來會觸發 onAppear，剛好對上。
  - 未來要更即時再升級為「manager 可觀察」或「存檔後 callback」。

---

## 5. 狀態判定演算法

以**日曆日差**計算，兩個日期都取當天 00:00（忽略時分秒、依裝置當地時區）：

```
daysUntil = Calendar.dateComponents([.day], from: 今天起始, to: 到期日起始).day
```

| daysUntil | ExpiryStatus | 顏色 |
|---|---|---|
| `< 0` | `expired` 已過期 | 🔴 紅 |
| `0 ≤ daysUntil ≤ 3` | `nearExpiry` 3 天內（含到期當天、含第 3 天） | 🟡 黃 |
| `> 3` | `fresh` 期限內 | 正常 |

- **到期當天（daysUntil=0）= `nearExpiry`（黃），不算 expired**——多數食材當天仍可用，且通知也在當天。
- 過了到期日**隔天**（daysUntil<0）才轉 `expired`。
- 「3 天」門檻為常數，可日後滾動調整。

## 6. iCloud 同步與資料遷移

### 容器建立
- 啟動時依「iCloud 開關」偏好（存於 UserDefaults），manager 建立**掛或不掛 `cloudKitDatabase`** 的 ModelContainer。
- opt-in、預設關、**變更後重啟生效**（不做執行期熱切換）。
- **開/關同步皆指向同一個本機 store 檔案**（URL 固定），這是雙向遷移能無痛的前提。
- schema 從一開始即 CloudKit-safe（§2.1），故 iCloud 關閉時 model 仍為 CloudKit 形狀，開啟時無需 schema migration。

### 打開同步（關 → 開）
- 重建為掛 `cloudKitDatabase` 的 container 後，底層 `NSPersistentCloudKitContainer` **自動將既有本機資料鏡射上傳**，無需自訂搬資料程式碼。
- 既有本機資料會被同步（符合使用者「打開就是要備份我全部資料」的期待）。
- 上傳為背景非同步，非即時完成。

### 關閉同步（開 → 關）
- 重建為不掛 CloudKit 的 container，指向同一 store。**本機資料續用**。
- **雲端副本留著不動**（「關閉 = 停止同步」，非「刪除備份」）。之後再打開會自動合併接回。

### 圖片備份
- 圖片以 `@Attribute(.externalStorage)` 存於 SwiftData，隨上述機制一併同步，無 Documents 外部檔的遺漏問題（§3）。

## 7. IAP 移除廣告

> **v1 延後（里程碑 2）**：AdMob 未接前「移除廣告」無實際效果，故**購買邏輯延後**。v1 僅：
> - 保留設定的「移除廣告 / 還原購買」**UI**（互動 stub，不真的走 StoreKit）。
> - 保留 `adsRemoved` state（v1 寫死 `false`），供 `AdSlotView` 的「持有即隱藏」邏輯先接好。
>
> 以下為未來接上時的完整設計：

- **StoreKit 2**，一次性（非消耗型）購買。
- **購買狀態來源：`Transaction.currentEntitlements`**，不自存旗標。App 啟動 / 進前景時查詢是否持有「移除廣告」entitlement。
  - 換裝置只要同一 Apple ID，StoreKit 自動認得，無需手動 Restore 即可還原。
- 設定仍保留「**還原購買（Restore）**」按鈕（Apple 審核慣例），正常情況免手動。
- 持有 entitlement → 首頁廣告 section 隱藏（呼應 `01-navigation`）。
- 監聽 `Transaction.updates` 以即時反映購買 / 退款。

## 8. 通知（Local Notification）

### 提醒時機
- 固定**到期當天 09:00**（`UNCalendarNotificationTrigger`）。時間為常數，可日後調整。
- 不做自訂天數、不做自訂時間（Spec 精神）。

### 排程單位
- **每項食材一則**通知，以食材 `id` 為通知 identifier（一對一）。
- 同一天多項到期 → 多則通知。未來食材量大再優化為「每天彙整一則」。

### 權限請求
- **情境式**：使用者**第一次新增食材、按儲存時**才請求通知權限（同意率高）。
- 被拒的引導文案於 `03-screens` 定義（導向系統設定）。

### 排程 / 取消規則
- **新增**（且到期日 09:00 尚未過）→ 排程。
- **編輯 / 延長效期**（改到期日）→ 取消舊排程 + 依新到期日重排。
- **刪除 / 標記已使用 / 標記丟棄**（離開 active）→ 取消該食材排程。
- **到期日的 09:00 已過**（例如新增一筆今天稍晚才記、或到期日已過去）→ 該筆不排程（過去時間無法觸發）。

### 點擊處理
- 點擊通知 → AppRouter 切到**首頁 Tab**（v1 不定位單一食材，見 `01-navigation` §7）。

### 已知限制與補排
- iOS 待發通知上限 **64 則 / App**。v1 採每項一則，若待排程數逼近上限，**以最接近到期者優先**排程（nearest-first）。
- **補排時機**：App **啟動 / 進前景時**做一次對帳——移除已離開 active 者的殘留排程、補排下一批最近到期者。量大時再評估改「每天彙整一則」。

## 9. 廣告與 ATT（App Tracking Transparency）

> **v1 延後（里程碑 2）**：不接 AdMob SDK。改以 **`AdSlotView` 佔位 seam**：
> - **DEBUG**：顯示灰底「Ad Placeholder」框（開發時看得到保留版面）。
> - **Release**：collapse 不佔空間。
> - 未來接 AdMob 時只換 `AdSlotView` 內部實作，首頁與 IAP 隱藏邏輯不動。
>
> 以下為未來接上時的完整設計：

- **AdMob**：首頁頂部單一 banner section（`01-navigation` §2），持有「移除廣告」entitlement 時隱藏。
- **ATT 觸發時機**：**App 冷啟動、首次進入首頁、且廣告即將載入前**才請求 ATT 授權（`ATTrackingManager`）。不在 App 一開就跳（無情境、易被拒）。
- **拒絕個人化追蹤** → 改請求**非個人化廣告**（AdMob `npa=1`），合規但收益較低。
- ATT 與通知權限為**兩次不同的系統彈窗**，避免同時連續轟炸使用者；ATT 綁廣告載入、通知綁首次儲存，時機自然錯開。

## 10. Schema 遷移

- 首版採 SwiftData 預設 schema。**預留 `VersionedSchema` + `SchemaMigrationPlan`** 的接法，未來欄位變更走輕量 / 自訂 migration，避免破壞既有使用者資料（尤其已同步至 CloudKit 者）。
- CloudKit 有 schema 變更限制（欄位只能加不能改型別 / 不能刪），故 model 演進須**只加不改**，配合 §2.1 的 CloudKit-safe 原則。
