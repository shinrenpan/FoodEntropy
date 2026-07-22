# 03 · 設定

> 狀態：✅ 定案
> 上游：`../01-navigation.md`（§6）、`../02-architecture.md`（§6 §7 §8）
> 對應：`SettingsView` + `SettingsViewModel`（@Observable @MainActor）

---

## 版面（分區）

### Section 1：購買
> **v1**：UI 保留，但**購買邏輯 stub**（AdMob + IAP 延後至里程碑 2，見 `02-architecture` §7）。

| 項目 | 行為（未來完整版） | v1 |
|---|---|---|
| 移除廣告 | 未購買 → 顯示價格 / 「購買」，點擊走 StoreKit 2。已持有 → 顯示「已移除」並停用。 | UI 在，點擊 no-op / 「即將推出」 |
| 還原購買 | 點擊執行 StoreKit restore。 | UI 在，點擊 no-op |

### Section 2：同步與通知
| 項目 | 行為 |
|---|---|
| iCloud 同步 | 開關，**預設關**。切換 → 存偏好（UserDefaults）+ 跳提示「設定已變更，將於下次開啟 App 後生效」。**不即時重建 container**（`02-architecture` §6）。 |
| 通知 | 顯示目前系統權限狀態（已開啟 / 已關閉 / 未設定）。若非「已開啟」，點擊 → 導向**系統設定**（`UIApplication.openSettingsURLString`）。App 內無法直接改系統權限。 |

### Section 3：關於
| 項目 | 行為 |
|---|---|
| 隱私權政策 | 點擊 → **App 內 SFSafariViewController** 開啟託管網頁。同一 URL 另填入 App Store Connect Privacy Policy URL（送審必要）。 |
| 版本 | 唯讀顯示 version + build number。 |

---

## 權限被拒引導（呼應 `form.md`）

- 「通知」列即為引導入口：使用者若在首次請求時拒絕，之後可於此看到「已關閉」並一鍵前往系統設定開啟。

---

## State（草案）

```swift
extension SettingsViewModel {
  struct State: Equatable, Sendable {
    var adsRemoved: Bool = false                 // 來自 IAP entitlement
    var productPriceText: String = ""            // 移除廣告價格
    var iCloudSyncEnabled: Bool = false          // 偏好值（重啟才實際生效）
    var notificationStatus: NotificationStatus = .notDetermined
    var showRestartNotice: Bool = false
    var showPrivacySheet: Bool = false
    var versionText: String = ""

    enum NotificationStatus: String, Sendable { case authorized, denied, notDetermined }
  }
}
```

## Action（doAction 單一進入點，草案）

```swift
enum Action {
  case onAppear                 // 載入 entitlement / 價格 / 通知狀態 / 偏好 / 版本
  case tapRemoveAds             // 購買
  case tapRestore               // 還原購買
  case toggleICloudSync(Bool)   // 存偏好 + showRestartNotice
  case tapNotification          // 非 authorized → 開系統設定
  case tapPrivacyPolicy         // showPrivacySheet
}
```

---

## 交由後續處理

- StoreKit 產品 ID、AdMob unit ID、隱私權政策網頁 URL、ATT 觸發時機等具體值於 `04-tasks` / 實作階段填入。
