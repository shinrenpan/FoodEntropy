## Summary

補回 v1.0.0 的持久化邊界 baseline：`@Model` 的 CloudKit-safe 約束、`toDomain()` 邊界轉換與「絕不外洩 `@Model`」的鐵則、明確重撈的資料流、查詢排序契約、圖片壓縮與存放，以及讀寫失敗的處理方式。無行為變更。

## Motivation

這一層集中了本專案最多「現在看起來多餘、未來會付出代價」的約束：

- **schema 從第一天就是 CloudKit 形狀**——每個屬性有預設值或 optional、沒有 `@Attribute(.unique)`——即使 iCloud 同步預設關閉。理由是同步是可隨時開啟的開關，若 model 不是 CloudKit-safe，使用者按下開關的那一刻就會 crash。這種「為了尚未發生的事而放棄資料庫層約束」的決定，沒有寫成規格就很容易在某次重構中被當成疏漏「修正」回去。
- **標記已使用或丟棄時會把圖片剝離**（`imageData = nil`）。這是為了省本機與 iCloud 空間的刻意取捨，但它是不可逆的資料破壞：一旦標記，照片就回不來了。目前只有一行註解說明。
- **讀取失敗一律回空集合、寫入失敗只在 debug 中斷**。這讓 app 永遠不會因資料層錯誤而崩潰，代價是失敗是靜默的。這個取捨需要被明確記錄，而不是被當成沒處理錯誤。

## Proposed Solution

從 `Sources/Core/Persistence/FoodItemEntity.swift`、`Sources/Core/Persistence/SwiftDataManager.swift`、`Sources/Core/Image/ImageCompressor.swift` 與 `specs/02-architecture.md` §1 §2.1 §3 §4 §10 寫出 `persistence` capability spec，涵蓋：CloudKit-safe schema 約束、DTO 與 Domain 的邊界、明確重撈的資料流、兩個查詢的排序契約、狀態轉移時的圖片剝離、圖片壓縮參數，以及失敗處理策略與 schema 演進限制。

## Non-Goals

- 無行為變更。
- 不涵蓋兩軸狀態的語意與效期判定演算法，那屬 `food-item`；本 capability 只規範它們如何落地與被查詢。
- 不涵蓋 iCloud 開關的使用者流程與生效時機，那屬 `icloud-sync`；本 capability 只規範 schema 必須恆為 CloudKit-safe。
- 不涵蓋 store 建立失敗的三層降級，那屬 `app-shell`（由它在啟動時執行）。
- 不涵蓋各畫面何時觸發重撈，那屬各畫面自己的 capability。

## Capabilities

### New Capabilities

- `persistence`：CloudKit-safe `@Model` 約束、`toDomain()` 邊界、明確重撈資料流、查詢排序契約、圖片壓縮與剝離、失敗處理與 schema 演進限制。

### Modified Capabilities

（無）

## Impact

- Affected specs: new `persistence`
- Affected code:
  - New: （無 —— 記錄既有程式碼）
  - Modified: （無）
  - Removed: （無）
  - Reference: `Sources/Core/Persistence/FoodItemEntity.swift`, `Sources/Core/Persistence/SwiftDataManager.swift`, `Sources/Core/Image/ImageCompressor.swift`, `specs/02-architecture.md`
