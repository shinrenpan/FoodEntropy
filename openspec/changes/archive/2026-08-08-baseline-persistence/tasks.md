## 1. Baseline 文件化

- [x] 1.1 從 `FoodItemEntity` 的屬性宣告寫出 requirement「The persisted model stays CloudKit-safe whether or not sync is on」；驗證：`grep -n "unique" Sources/Core/Persistence/FoodItemEntity.swift` 僅命中第 6 行——說明「無 `@Attribute(.unique)`（CloudKit 不支援）」的註解，屬性宣告本身無此標註；且每個非 optional 屬性皆帶 `= ` 預設值。
- [x] 1.2 從 `statusRaw` 欄位與 `toDomain()` 的 `RecordStatus(rawValue:) ?? .active` 寫出 requirement「Record status is persisted as a raw string and unknown values fall back to active」；驗證：`toDomain()` 內可見該 nil-coalescing 退回。
- [x] 1.3 從 `SwiftDataManager` 的公開方法簽章與 `FoodItemEntity.toDomain()` 的定義位置寫出 requirement「The persistence layer never exposes its model type」；驗證：`grep -n "func .*FoodItemEntity\|-> FoodItemEntity" Sources/Core/Persistence/SwiftDataManager.swift` 僅命中 private 的 `entity(for:)`，公開 API 不出現該型別。
- [x] 1.4 從專案未使用 `@Query`、資料由 `@MainActor` manager 提供的事實寫出 requirement「Data is delivered by explicit re-fetch, not by automatic observation」；驗證：`grep -rn "@Query" Sources` 無結果。
- [x] 1.5 從 `fetchActiveFoods` / `fetchResolvedFoods` 的 `FetchDescriptor` 寫出 requirement「Query ordering is part of the data contract」；驗證：前者帶 `expiryDate` 與 `createdAt` 兩個 `.forward` sort descriptor，後者帶 `resolvedAt` 的 `.reverse`。
- [x] 1.6 從 `resolve(id:to:)`、`delete(id:)`、`update(...)` 寫出 requirement「Resolving an item records the resolution time and strips its photo」；驗證：`resolve` 內同時設定 `statusRaw`、`resolvedAt = .now`、`imageData = nil`，且 `update` 不觸及 `statusRaw`。
- [x] 1.7 從 `ImageCompressor` 的縮圖與壓縮實作寫出 requirement「Photos are downscaled and compressed before they are stored」；驗證：`resized` 內設 `format.scale = 1` 且長邊未超標時原樣返回；`compressedJPEGData` 預設 `maxDimension` 1024、`quality` 0.7。
- [x] 1.8 從各 fetch 的 `(try? ...) ?? []` 與 `save()` 的 `assertionFailure` 寫出 requirement「Read failures yield empty results and write failures fail loudly only in debug」；驗證：`grep -c "try? context.fetch" Sources/Core/Persistence/SwiftDataManager.swift` 為 4，且 `save()` 的 catch 分支呼叫 `assertionFailure`。
- [x] 1.9 從 `02-architecture` §10 的 CloudKit 限制寫出 requirement「Schema evolution is additive only」；驗證：規格文字明確禁止改型別與刪欄位，與 CloudKit Production schema 的實際限制一致。

## 2. 收尾

- [x] 2.1 執行 `spectra validate baseline-persistence`；驗證：指令回傳成功、無 error。
- [x] 2.2 archive 後補上 `openspec/specs/persistence/spec.md` 的 `## Purpose` 段；驗證：`grep -c "TBD" openspec/specs/persistence/spec.md` 為 0。
