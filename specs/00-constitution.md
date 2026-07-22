# 00 — 專案憲章（Constitution）

> 狀態：✅ 定案
> 本文件為**不可違反前提**，凌駕於所有畫面與功能規格之上。後續 spec 與實作皆須遵守。

---

## 平台與裝置

| 項目 | 決定 | 備註 |
|---|---|---|
| 支援裝置 | **iPhone only** | 不做 iPad / Mac；Spec 為手機使用情境，省 iPad 版面成本 |
| 最低 iOS | **iOS 26+** | SwiftData/CloudKit 最成熟版本；iOS 18 之 SwiftData v2 同步有破壞性 quirks，iOS 17 更早期 |
| 螢幕方向 | **直向鎖定（Portrait only）** | 清單型 App 慣例 |
| 深色模式 | **支援** | 跟隨系統，light / dark 皆須正常 |

### 未來版本評估
- iOS 27（WWDC 2026）對 SwiftData 為 **additive、非 breaking**。未來可評估把下限抬至 **iOS 27** 以採用：
  - **ResultsObserver** → 將刷新機制（`02-architecture` §4）從「onAppear 重撈」升級為觀察式自動刷新。
  - **Sectioned Queries** → 簡化分析畫面（`03-screens/analytics.md`）的狀態分桶。
  - **Enum predicate / `.codable`** → 或可優化 `statusRaw: String` workaround（CloudKit 約束仍須驗證）。

---

## 架構

| 項目 | 決定 |
|---|---|
| 架構模式 | **MVVMC**（Model-View-ViewModel-Coordinator/Router） |
| UI | SwiftUI（透過 HostController 橋接 UIKit Router） |
| 資料 | SwiftData（本地）+ CloudKit（opt-in 同步） |
| 分層 | `@Model`(持久化 DTO) → Manager(`toDomain()`) → ViewModel → State → View（見 `02-architecture` §1） |
| 專案生成 | **XcodeGen**（`project.yml` 宣告，`.xcodeproj` 不進版控、由 yml 生成） |
| 相依管理 | **Swift Package Manager**（AdMob 等） |

### 遵循的既有規範（skills）
- `mvvmc-model` / `mvvmc-viewmodel` / `mvvmc-view` / `mvvmc-hostcontroller` / `mvvmc-navigation` / `mvvmc-testing`
- `swift-concurrency`

---

## 語言與並行

| 項目 | 決定 | 備註 |
|---|---|---|
| 在地化 | **String Catalog 架構，首版只填繁中（zh-Hant）** | 架構先做好，未來加語言不需重構；不硬編字串 |
| Swift Concurrency | **strict mode** | 依 `swift-concurrency` skill；正確判斷離開主 actor 的工具 |

---

## 品質基準（Production 門檻）

| 項目 | 要求 |
|---|---|
| 無障礙 | 支援 **Dynamic Type**（文字可放大不破版）、**VoiceOver**（元件有語意標籤）、尊重 Reduce Motion |
| 深色模式 | light / dark 皆須正常，顏色用語意化 token（狀態色在兩種模式都可辨識） |
| 在地化 | 所有面向使用者字串走 String Catalog；日期 / 數字用系統格式化（尊重使用者地區） |
| 觸控目標 | 互動元件符合最小點擊區（FAB、row 操作） |

## 依賴原則

- **不接第三方 Analytics / Crash SDK**（如 Firebase）→ 用 Xcode Organizer + App Store Connect Analytics（Spec Production §5）。
- 第三方僅限：**Google AdMob SDK**（廣告）。
- 其餘一律優先系統原生框架。

---

## 不可違反鐵則（摘要）

1. ViewModel / State **永不持有 SwiftData `@Model`**，只吃 Domain Model。
2. Model 須 **CloudKit-safe**（全欄位有預設值、無 `.unique`、關聯 optional），即使同步關閉亦然。
3. 字串一律走 String Catalog，**不硬編**。
4. 遵守 MVVMC 各層 skill 規範，不繞過 Router 做導航。
