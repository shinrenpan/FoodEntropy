## Context

本專案沒有後端 API，因此 MVVMC 慣例中的 DTO 角色由 SwiftData 的 `@Model` 扮演：它是「從磁碟來的原始資料」，帶著持久化層的所有妥協（`statusRaw` 是 String 而非 enum、每個欄位都有預設值），經 `toDomain()` 轉成乾淨的 `FoodItem` 之後才交給上層。ViewModel 完全不知道 SwiftData 存在。

這一層的所有設計取捨幾乎都來自同一個前提：**iCloud 同步是使用者可以隨時打開的開關**。這使得 schema 必須永遠處於 CloudKit 形狀，即使絕大多數使用者從未打開它。

## Goals / Non-Goals

**Goals:**
- 記錄 CloudKit-safe 三條約束與「即使同步關閉也必須遵守」的理由。
- 記錄 DTO/Domain 邊界，以及 `@Model` 不得外洩的鐵則。
- 記錄兩個查詢的排序契約。
- 記錄狀態轉移時剝離圖片的取捨與不可逆性。
- 記錄圖片壓縮參數與其中 `scale = 1` 的用意。
- 記錄讀寫失敗的處理策略與其代價。
- 記錄 schema 只加不改的演進限制。

**Non-Goals:**
- 無行為變更。
- 不涵蓋 `food-item` 的狀態語意、`icloud-sync` 的開關流程、`app-shell` 的降級啟動。

## Decisions

### schema 恆為 CloudKit-safe，即使同步關閉

`FoodItemEntity` 的每個非 optional 屬性都有預設值，沒有任何 `@Attribute(.unique)`，未來新增的關聯也必須 optional。理由：CloudKit 的資料模型不支援必填欄位與唯一性約束，`NSPersistentCloudKitContainer` 在掛載一個不相容的 schema 時會直接失敗。由於同步是使用者隨時可切換的開關，schema 只要有一刻不是 CloudKit 形狀，使用者打開開關的那一刻 app 就掛了——而那是最糟的時機，因為使用者剛表達「我要備份我的資料」。從第一天就維持 CloudKit 形狀，換來的是開關兩個方向都不需要任何 schema migration。考慮過的替代方案：只在使用者啟用同步時才切換到 CloudKit-safe schema——否決，那等於在執行期做 schema migration，是風險最高的一種變更。

代價是「必填」無法由資料庫把關，改由 Form 驗證負責；`id` 的唯一性也由程式邏輯（UUID 生成）保證而非 DB 約束。

### 狀態以 String raw value 儲存，而非 enum 型別

`statusRaw: String` 而非直接存 `RecordStatus`。理由：CloudKit 對可儲存型別有限制，String 是最保險的表示。讀取時以 `RecordStatus(rawValue:) ?? .active` 轉回——未知值退回 `active` 而不是拋錯或丟棄該筆。理由：未知值只可能來自未來版本寫入、由舊版本讀到（CloudKit 同步的跨版本情境），此時把資料當成「還在清單裡」比讓它消失安全——使用者至少看得到它，可以自己處理。

### manager 回傳 Domain，`@Model` 絕不外洩

所有讀取方法都在回傳前 `map { $0.toDomain() }`，manager 的公開 API 沒有任何一個型別是 `@Model`。`toDomain()` 定義在 `FoodItemEntity` 自身的 extension 上——轉換是 DTO 自己的責任。理由：`@Model` 實例綁在 `ModelContext` 上，具有隱含的執行緒與生命週期約束；讓它流進 ViewModel 或 State，等於把持久化層的限制傳染到整個上層，也讓 ViewModel 無法在沒有 SwiftData 的情況下被測試。

### 無 `@Query`，改為明確重撈

不使用 SwiftUI 的 `@Query`，資料一律由 `@MainActor` 的 manager 主動提供。理由：`@Query` 需要 view 直接接觸 `@Model`，與上一條鐵則衝突。代價是清單不會自動響應資料變動，需要明確的重撈時機——這由 `navigation` 的 push/pop 搭配畫面的出現回呼提供。iOS 27 的 ResultsObserver 是既定的升級路徑，屆時可在不打破 DTO 邊界的前提下取得觀察能力。

### 排序是查詢的一部分，不是呈現的責任

現存食材依 `expiryDate` 升冪、同日者再依 `createdAt` 升冪；已處理食材依 `resolvedAt` 由新到舊。理由：把排序放進 `FetchDescriptor` 讓它成為資料層契約的一部分，任何呼叫端拿到的順序都一致；次要排序鍵 `createdAt` 則保證同一天到期的多筆食材有穩定順序，不會因每次查詢而跳動。

### 離開 active 時剝離圖片

`resolve()` 在設定 `statusRaw` 與 `resolvedAt` 的同時把 `imageData` 設為 `nil`。理由：已使用或已丟棄的食材只作為統計素材存在，不再需要在任何畫面顯示照片；而照片是這個 app 唯一體積大的資料（每張 100–300KB），長期累積會同時佔用本機與使用者的 iCloud 配額。剝離讓歷史紀錄的體積趨近於零。考慮過的替代方案：保留圖片、僅在超過一定筆數時清理——否決，那需要額外的清理策略與時機，而歷史照片沒有任何已知用途。

這是不可逆的：標記之後照片無法復原。接受此代價，因為四種出口中只有「刪除」是為了修正誤操作，而它本來就連紀錄一起移除。

### 圖片在取得當下即壓縮，不存原圖

拍照或選圖後立刻等比縮至長邊 1024px、以 JPEG quality 0.7 壓縮，再存入 `@Attribute(.externalStorage)`。理由：原圖動輒數 MB，存原圖會讓同步變慢且吃掉 iCloud 配額，而清單縮圖與編輯頁預覽都不需要那個解析度。縮圖時明確設定 `format.scale = 1`，讓輸出以「點等於像素」計算——否則在 @2x/@3x 裝置上 `UIGraphicsImageRenderer` 會產出 2 至 3 倍的像素量，長邊上限形同虛設。

`externalStorage` 讓 SwiftData 自行決定大 blob 的存放方式，並且仍在 CloudKit 的同步範圍內——這是相對於「自行存 Documents 目錄」的關鍵優勢，後者不會隨 CloudKit 備份。

### 讀取失敗回空集合，寫入失敗只在 debug 中斷

所有 fetch 都是 `(try? context.fetch(descriptor)) ?? []`；`save()` 失敗時呼叫 `assertionFailure`。理由：資料層錯誤不應該讓一個食材清單 app 崩潰——使用者寧可看到空清單也不要閃退。`assertionFailure` 讓開發期的寫入失敗立刻現形，Release 則靜默繼續。代價是 Release 中的失敗不會通知使用者，這在下方 Risks 記錄。

### schema 只加不改

未來的 model 演進只能新增欄位，不能改型別或刪除欄位，並預留 `VersionedSchema` + `SchemaMigrationPlan` 的接法。理由：CloudKit 的 schema 一旦部署到 Production 就無法修改或刪除欄位；已同步的使用者資料受此限制約束，與本機是否遷移無關。

## Implementation Contract

**Behavior (observable):**
- 新增一筆食材後重新開啟 app，該筆仍在清單中。
- 清單中同一天到期的多筆食材，每次開啟的相對順序都相同。
- 標記某筆為已使用後，該筆離開清單，且其照片不再佔用儲存空間。
- 選取一張高解析度照片後，儲存的資料量約在數百 KB 量級，而非原圖大小。
- 資料庫讀取失敗時，畫面呈現空清單而非崩潰。

**Interface / data shape:**
- `FoodItemEntity`：`@Model final class`；`id` / `name` / `purchaseDate` / `expiryDate` / `statusRaw` / `createdAt` 皆有預設值，`resolvedAt` / `imageData` 為 optional，`imageData` 標記 `@Attribute(.externalStorage)`；無 `@Attribute(.unique)`。
- `FoodItemEntity.toDomain() -> FoodItem`。
- `SwiftDataManager`：`@MainActor final class`，持有 private `ModelContainer`；讀取 `fetchActiveFoods()` / `fetchResolvedFoods()`，寫入 `create(name:purchaseDate:expiryDate:imageData:)` / `update(id:name:purchaseDate:expiryDate:imageData:)` / `markConsumed(id:)` / `markWasted(id:)` / `delete(id:)` / `deleteResolvedFoods()`；公開 API 的回傳型別皆為 `FoodItem` 或 `[FoodItem]`。
- `ImageCompressor.compressedJPEGData(from:maxDimension:quality:) -> Data?`，預設長邊 1024、quality 0.7。

**Acceptance criteria:**
- `FoodItemEntity` 內無 `.unique`，且每個非 optional 屬性皆有預設值。
- `SwiftDataManager` 的公開方法簽章中不出現 `FoodItemEntity`。
- `resolve` 路徑同時寫入 `statusRaw`、`resolvedAt`，並將 `imageData` 設為 `nil`。
- `fetchActiveFoods` 的 `FetchDescriptor` 帶有 `expiryDate` 與 `createdAt` 兩個升冪 sort descriptor。
- `ImageCompressor.resized` 在縮圖時設定 `format.scale = 1`。

**Scope boundaries:**
- In scope：schema 約束、DTO/Domain 邊界、查詢與排序、圖片壓縮與剝離、失敗處理、schema 演進限制。
- Out of scope：狀態語意與效期演算法（`food-item`）、iCloud 開關流程（`icloud-sync`）、啟動時的降級策略（`app-shell`）、各畫面的重撈時機。

## Risks / Trade-offs

- [讀取失敗靜默回空集合] → 資料庫損毀時使用者看到的是「我的食材都不見了」而非錯誤訊息，可能誤以為資料已遺失而重新輸入。接受此代價以換取不崩潰；若未來要改善，應在 manager 回傳型別中帶出失敗訊號，而非改成拋錯。
- [寫入失敗在 Release 靜默] → 使用者可能以為儲存成功，實際未落地，且下次重撈時該筆消失。這是目前最沒有防護的路徑；`assertionFailure` 只在開發期有效。
- [剝離圖片不可逆] → 誤按「已使用」會永久失去該筆照片，且沒有復原入口。目前四種出口都沒有 undo，這個代價與其他三者一致，但圖片是唯一無法靠重新輸入還原的資料。
- [`statusRaw` 未知值退回 `active`] → 若未來版本新增第四種狀態，舊版本會把它顯示為現存食材，使用者可能對它做出不合理的操作（例如把一筆已封存的紀錄再標記為已使用）。以目前只有三態且無新增計畫的情況可接受。
- [CloudKit 的只加不改限制] → 任何欄位型別調整（例如把 `statusRaw` 改成 enum）對已同步的使用者都不可行，只能新增欄位並保留舊欄位。這個限制會隨使用者基數增長而愈難繞過。
