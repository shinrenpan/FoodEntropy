## Why

WWDC 2026（2026-06-09）棄用 SiriKit，**App Intents 成為 Siri 呼叫第三方 app 的唯一途徑**。iOS 27 於 2026-09-14 發布（台灣 9/15），新 Siri 會跨 app 組合多步驟動作——有宣告 Intent 的 app 進入那個組合，沒有的直接被排除。

食熵的動作天生結構化（新增／已使用／丟棄／延長／查詢），可直接複用 `persistence` 既有的 CRUD，不需重寫業務邏輯。

本 proposal 原先卡在一項「只能用 iOS 27 SDK 確認」的前提而無法進入設計階段。**該前提已於 2026-09-11 用 Xcode 27 RC 確認完畢**，結論與原先推測不同，故本文件據以重寫。

## 前提確認結果（2026-09-11，Xcode 27.0 / 27A266a）

直接讀 `iPhoneOS27.0.sdk` 的 `AppIntents.swiftinterface` 取得，非文件推測。

**一、schema domain 共 22 個，確實沒有食材／庫存／購物：**

`Assistant` `Audio` `Books` `Browser` `Calendar` `Camera` `Clock` `Files` `Journal` `Mail` `Maps` `Messages` `Notes` `Phone` `Photos` `Presentation` `Reader` `Reminders` `Spreadsheet` `System` `VisualIntelligence` `Whiteboard` `WordProcessor`

**二、但存在不綁 domain 的逃生門**——原 proposal 據以推論「沒有 domain 就拿不到自然語言」的前提因此不成立：

```swift
@available(anyAppleOS 27.0, *)
extension AppSchema.SystemIntent {
    var searchInApp: some AppSchemaIntent   // SystemSearchInAppIntent
    var open: some AppSchemaIntent          // OpenIntent
}
```

任何 app 都能採用。可得「在食熵裡找牛奶」「打開食熵裡的牛奶」；**新增仍無自然語言路徑**（沒有任何 domain 提供「新增庫存品項」）。

**三、螢幕感知不需要 iOS 27**——原 proposal 誤將其列為 iOS 27 專屬：

| API | 實際可用版本 |
| --- | --- |
| `.appEntityIdentifier(_:)` / `(forSelectionType:)` SwiftUI modifier | **iOS 18.4** |
| `EntityIdentifier` | iOS 16.0 |
| `AppEntityAnnotatable` | iOS 18.2 |
| `UNMutableNotificationContent.appEntityIdentifiers` | **iOS 27.0** |
| `OwnershipProvidingEntity` / `IndexedEntityQuery` | iOS 27.0 |

**四、macro 已改名**：`@AssistantIntent` / `@AssistantEntity` / `AssistantSchemas` 全數標記 deprecated，改為 `@AppIntent(schema:)` / `@AppEntity(schema:)` / `AppSchema`。原 proposal 建議的驗證手法（`@AssistantIntent(schema:` 自動補完）會補到已棄用的 API。

## 可用性現況（決定範圍切分的主軸）

新 Siri 的 API 能力與**使用者實際拿得到的範圍**落差極大：

| | 需要 iOS 27 | 需要 Siri AI | 繁中使用者現在可用 |
| --- | --- | --- | --- |
| 捷徑 + Spotlight | ❌ | ❌ | ✅ |
| Spotlight 語義索引（`IndexedEntity`） | ❌（18.0） | ❌ | ✅ |
| `.system.searchInApp` / `.system.open` | ✅ | ✅ | ❌ |
| 螢幕感知標註 | ❌（18.4） | ✅ | ❌ |
| 到期通知的 entity 標註 | ✅ | ✅ | ❌ |

Siri AI 的門檻：**僅英文**（10 月加法／日／韓／葡／西，**繁中未公布日期**）、**iPhone 15 Pro 以上**、EU 的 iOS 不提供（台灣不在限制區）。

**但開發端可完整驗證**：作者持有 iPhone 15 Pro 且已升 iOS 27 RC，將裝置語言切為英文即可啟用 Siri AI。12GB RAM 門檻只擋「Siri 語音表情調整」與「進階聽寫」，螢幕感知、app actions、personal context 全部支援。因此本 change 不需要為了「做了也測不了」而延後 Siri 專屬部分。

## What Changes

- 新增 `app-intents` capability：`FoodItemEntity`（App Intents 的 `AppEntity`，與 persistence 的 `FoodItemEntity` `@Model` 同名衝突，實作時需另行命名）、entity query、六個 Intent、`AppShortcutsProvider`。
- 六個 Intent：新增食材、標記已使用、標記丟棄、延長效期、開啟食材、尋找食材。全部複用 `SwiftDataManager` 既有方法，不新增業務邏輯。兩個 system schema 最終皆未採用，理由見 design 的決策四與決策十。
- 食材進入 Spotlight 語義索引（`IndexedEntity`），可用自然語言在 Spotlight 找到，而非字串比對。
- 首頁清單與食材列曝露 `.appEntityIdentifier`，Siri 得以解析「這個」。
- 到期通知帶上 entity 標註，使用者看到通知時可對 Siri 說「這個延長三天」。
- **`persistence` 契約變更**：App Intents 在沒有 scene 的情況下執行，需要一個 process 層級的 `SwiftDataManager` 取用點，取代目前只在 `SceneDelegate` 建立的單一路徑。
- **`notification` 契約變更**：通知內容新增 entity 標註欄位。
- 部署基準**維持 iOS 26**，iOS 27 專屬能力以 `@available(iOS 27.0, *)` 包覆。

## Capabilities

### New Capabilities

- `app-intents`：Intent 與 Entity 的定義、與既有 CRUD 的對應、可觸發表面（捷徑／Spotlight／Siri）、螢幕感知標註的契約。

### Modified Capabilities

- `persistence`：新增 process 層級的 `SwiftDataManager` 取用契約，供無 scene 的 App Intents 執行路徑使用；原本「由 `SceneDelegate` 建立」的單一來源不再成立。
- `notification`：到期通知的內容契約新增 entity 標註，使 Siri 能將通知對應到食材。
- `navigation`：新增「單筆食材」的 deeplink 目標，供 Spotlight 點擊結果與助理的開啟動作共用；原本僅有首頁一個目標。

## Impact

- Affected specs: `app-intents`（新增）、`persistence`（修改）、`notification`（修改）、`navigation`（修改）
- Affected code:
  - New：`Sources/Core/Intents/`（Entity、query、六個 Intent、`AppShortcutsProvider`）
  - Modified：`Sources/Core/Persistence/SwiftDataManager.swift`（process 層級取用點）、`Sources/App/SceneDelegate.swift`（改用該取用點）、`Sources/Core/Notification/NotificationService.swift`（entity 標註）、`Sources/Features/Home/HomeView.swift`（螢幕感知標註與前景重載）、`Sources/App/Deeplink.swift`（單筆食材目標）、`Sources/Resources/Localizable.xcstrings`（Intent 標題與 Siri 語句）、`openspec/specs/README.md`（capability map 新增 `app-intents`）
  - Reference：`Sources/Core/Domain/FoodItem.swift`、`Sources/Widget/WidgetStore.swift`（process 外開 store 的既有作法）
- 外部相依：**iOS 27 SDK（Xcode 27）**。部署基準不變（iOS 26）。
- 無新增第三方相依（符合憲章：AdMob 為唯一第三方）。

## 來源

- iOS 27 SDK `AppIntents.swiftinterface`（`iPhoneOS27.0.sdk`）——domain 清單、API 可用版本、macro 改名的第一手依據
- [WWDC26: Explore advanced App Intents features for Siri and Apple Intelligence](https://developer.apple.com/videos/play/wwdc2026/343/)
- [WWDC26: Build intelligent Siri experiences with App Schemas](https://developer.apple.com/videos/play/wwdc2026/240/)
- [Apple Developer News: App Store submissions now open](https://developer.apple.com/news/?id=k1mtkt1k)
- [9to5Mac: Siri AI launches in English this month, five languages in October](https://9to5mac.com/2026/09/09/apple-confirms-siri-ai-launches-in-english-this-month-will-add-five-languages-in-october/)
- [MacRumors: iPhone 17's 8GB limit costs it these two Siri AI features](https://www.macrumors.com/2026/06/10/iphone-17s-8gb-limit-loses-siri-ai-features/)
