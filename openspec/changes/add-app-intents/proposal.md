## Summary

把食熵的核心動作（新增食材、標記已使用、查詢即將到期）曝露為 App Intents，使其可在捷徑、Spotlight 與 Siri 中被觸發。**範圍尚未確定**——取決於一項只能用 iOS 27 SDK 確認的前提，見下方「待確認前提」。本 proposal 先固定目標、已知約束與決策點；設計與任務待前提釐清後補上。

## Motivation

WWDC 2026（2026-06-09）正式棄用 SiriKit，App Intents 成為 Siri 呼叫第三方 app 的**唯一**途徑。新 Siri 由 Google Gemini 模型驅動，會跨 app 組合多步驟動作——有宣告 Intent 的 app 進入那個組合，沒有的直接被排除在外。既有 SiriKit 實作僅在 iOS 26 以下有效，且已產生編譯期棄用警告，Apple 給出約兩到三年的支援窗口。

食熵的動作天生結構化（新增／已使用／查詢），是 App Intents 的合適對象，且邏輯可直接複用 `persistence` 的既有 CRUD，不需重寫。

## 待確認前提（決定本 change 的範圍）

**Siri 的自然語言理解僅對 schema-based 的 Intent 生效。** WWDC26 session 的原話是：「App Intents expose actions to the system. App schemas make those actions understandable by Siri.」兩者是分開的能力。

而 `@AssistantIntent(schema:)` 只涵蓋預定義 domain——查到的清單包含 Messages、Mail、Photos、Contacts、Documents、Books、Journal、Presentations、Spreadsheets、System 等系統常見概念，**食材／庫存不在其中**。

若確實沒有可用的 domain，則「跟 Siri 說『加一盒牛奶，後天到期』」這類自然語言操作**做不到**，能拿到的只有捷徑與 Spotlight。

**確認方式**：安裝 Xcode 27 後，以 `@AssistantIntent(schema:` 的自動補完列出完整 domain 清單，確認有無食材／庫存／購物之類可用者。成本約 30 分鐘，是本 change 的第一項工作。

> 上述 domain 清單來自 WWDC26 session 頁面摘要，非逐字查證，且可能未涵蓋 iOS 27 新增項目。實際以 SDK 為準。

## 三層可觸發性（已查證）

| 層級 | 需要什麼 | 現在（iOS 26）可做 |
|---|---|---|
| 捷徑 App | 任何 `AppIntent` | ✅ |
| Spotlight 執行動作 | 任何 `AppIntent` | ✅ |
| Siri 自然語言 | schema-based Intent | ❌ 前提未確認 |

## 候選範圍（擇一，待前提釐清後決定）

**A. 僅捷徑與 Spotlight** — 定義 `AppIntent`、`AppEntity`、`AppShortcutsProvider`，複用既有 CRUD。iOS 26 即可實作，不需等待。拿不到 Siri 對話。

**B. 完整整合** — 在 A 之上加入 iOS 27 專屬能力：`IndexedEntity`（把食材餵進 Spotlight 的語義索引，非字串比對）、View Annotations（`.appEntityIdentifier`，螢幕感知，讓使用者指著畫面說「這個」）、`IntentValueQuery`（跨 app 內容媒合）、`AppIntentsTesting`（新測試框架）。需 iOS 27 SDK；若同時要求執行期能力，須評估是否拉高部署基準。

選 B 且要求 iOS 27 執行期能力時，拉高部署基準會捨棄 iOS 26 使用者——本 app 上架未久、基數小，代價相對低，但仍是獨立決定，不由本 change 預先決定。

## Proposed Solution

待前提確認後，於後續補上 design 與 tasks。無論選 A 或 B，共同的骨幹是：以 `persistence` 既有的 CRUD 為實作來源定義 Intent 與 Entity，不重寫業務邏輯；`FoodItem` 曝露為 `AppEntity` 並提供對應的 query。

## Non-Goals

- 不重寫既有業務邏輯——Intent 呼叫 `persistence` 的既有方法。
- 不在本 change 決定是否拉高部署基準至 iOS 27。
- 不涵蓋 Widget（屬另一個尚未決定的項目）。
- 不涵蓋 SiriKit 的相容或遷移——本專案從未實作 SiriKit。

## Capabilities

### New Capabilities

- `app-intents`（暫定）：Intent 與 Entity 的定義、與既有 CRUD 的對應關係、可觸發表面。範圍確定後補上 delta spec。

### Modified Capabilities

（待定）視最終範圍，可能影響 `food-item`（`FoodItem` 曝露為 `AppEntity` 的欄位需求）與 `persistence`（Intent 執行路徑的資料存取）。

## Impact

- Affected specs: 待定
- Affected code:
  - New: App Intents 相關型別（位置待定，依 MVVMC 資料夾慣例應在 `Sources/Core/` 或新的 feature 目錄）
  - Modified: 可能需要在 `Sources/Core/Domain/FoodItem.swift` 補 `AppEntity` 相關宣告
  - Reference: `Sources/Core/Persistence/SwiftDataManager.swift`, `Sources/Core/Domain/FoodItem.swift`
- 外部相依：**iOS 27 SDK（Xcode 27）**；iOS 27 公開發布為 2026 年 9 月
- 本 change 在前提確認前無法進入設計階段，故 park

## 來源

- [WWDC26: Build intelligent Siri experiences with App Schemas](https://developer.apple.com/videos/play/wwdc2026/240/)
- [WWDC26: Explore advanced App Intents features for Siri and Apple Intelligence](https://developer.apple.com/videos/play/wwdc2026/343/)
- [WWDC26: Discover new capabilities in the App Intents framework](https://developer.apple.com/videos/play/wwdc2026/345/)
- [WWDC26 Apple Intelligence guide](https://developer.apple.com/wwdc26/guides/apple-intelligence/)
- [AssistantIntent(schema:) — Apple Developer Documentation](https://developer.apple.com/documentation/appintents/assistantintent(schema:))
