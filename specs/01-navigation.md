# 01 — 導航結構

> 狀態：✅ 定案
> 上游：`archive/Spec.md`（產品規格，僅為討論種子，本文件為新的真實來源）

本文件定義 App 的畫面骨架、Tab 結構、各畫面職責與導航流。細部資料模型與同步機制留待 `02-architecture.md`。

---

## 1. Tab 結構

底部兩個 Tab：

| Tab | 職責 | 可操作 |
|---|---|---|
| 首頁 | 現況統計 + 管理食材（新增/編輯/滑動/長按） | ✅ 動手的地方 |
| 設定 | IAP、iCloud、通知、隱私權政策、版本 | ✅ |

**設計沿革（原三 Tab → 兩 Tab）**：原本「首頁（管理）」與「分析（唯讀總覽）」分兩 Tab，但分析頁的分桶清單本質是把首頁食材換個排法再列一次，**兩頁雷同**。故合併為**單一首頁**：頂部放現況甜甜圈 + 浪費統計（原分析頁內容），下方分桶清單改用首頁互動。避免功能與畫面重複。

---

## 2. 首頁（統計 + 食材清單，單頁）

由上而下的 List，細節見 `03-screens/home.md`：

### 版面
- **廣告**：釘在清單**最頂**（`safeAreaInset` top，加不透明底避免捲動穿透），標示「廣告」。有 fill 才 50pt 顯示、無 fill/失敗收合為 0（不留空框）。持有「移除廣告」entitlement 時整條不放。
- **現況甜甜圈**：active 三桶佔比 + 中心總數（原分析頁）。
- **浪費統計**：近 30 天浪費率 + 綠/紅比例條，header 右側「清除歷史」鈕（原分析頁）。
- **分桶清單**：依狀態分三 Section（**已過期未處理 / 3 天內到期 / 保存期限內**，急→緩），header 顯示桶名 + 數量，**空桶照顯示**。桶內 row 依到期日升冪、以顏色區分狀態（§4）。
- **新增按鈕**：底部**全寬填滿按鈕**「＋ 新增食材」（`safeAreaInset` bottom，與 tab bar 拉開避免誤觸）。取代原本的小圓 FAB。

### Row 操作（4 種出口，詳見 `02-architecture` §2.3）
- **向右滑（leading）**：標記已使用（`consumed`，移出清單）
- **向左滑（trailing）**：刪除（hard delete，**跳確認**）
- **長按 → context menu**：延長效期 / 標記已使用 / 標記丟棄（`wasted`）
- **單點整列 row** → push 進編輯頁（見 §3）
- **發現性**：最後一桶 Section footer 顯示 hint（點/滑/長按）。

### 空狀態（無任何食材）
- 廣告照常（有 fill 時）；甜甜圈顯示「目前沒有食材」、三個空桶顯示「沒有項目」、浪費統計顯示「尚無已處理紀錄」。
- 底部「＋ 新增食材」始終可用，引導新增。

---

## 3. 新增 / 編輯食材（共用 Form 畫面）

- **單一畫面 `FoodFormView`，兩種模式**：`add` / `edit`。
- **導航方式：Router push**（非 modal）。新增與編輯皆 push 進同一 Form 畫面，共用邏輯、單一導航堆疊。
- 進入點：
  - 首頁 FAB → push `FoodFormView(.add)`
  - 首頁 row 單點 → push `FoodFormView(.edit)`
- 欄位（詳細規格留 `03-screens`）：名稱（必填）、購買日期（必填，預設今天）、到期日期（必填，可給預設如今天+3天）、圖片（選填，拍照 / 相簿，未提供顯示預設圖示）。

### 生命週期備註
- 本專案**無 `@Query`**，資料由 `@MainActor` 的 SwiftDataManager 提供，首頁清單**不會自動響應**。新增 / 編輯後需**主動重撈刷新**。
- **刷新機制：onAppear 重撈**——Form pop 回首頁時觸發 `onAppear` → ViewModel 叫 manager 重撈（見 `02-architecture` §4）。選用 push 剛好對上：pop 回來會觸發 onAppear。
- 未來若抬到 iOS 27，可用 **ResultsObserver** 升級為觀察式自動刷新（見 `00-constitution`）。

---

## 4. 食材狀態定義（供顏色區分與分析分桶）

| 狀態 | 條件 | 用途 |
|---|---|---|
| 保存期限內 | 到期日 > 今天 + 3 天 | 綠色 |
| 3 天內到期 | 今天 ≤ 到期日 ≤ 今天 + 3 天 | 黃色警示 |
| 已過期未處理 | 到期日 < 今天，且仍為 `active`（尚未刪除 / 已使用 / 丟棄） | 紅色 |

> 精確邊界（含當天算法、時區）留 `02-architecture` / `03-screens` 定義。「3 天」為暫定值，可調。

---

## 5. 設定（Settings）

清單項目（由上而下暫定）：

| 項目 | 行為 |
|---|---|
| 移除廣告 | 一次性 IAP 購買 + **還原購買（Restore）**。購買後首頁廣告 section 消失。 |
| iCloud 同步 | **開關，預設關（opt-in）**。開啟才將資料同步至私有 iCloud container。變更後**需重新啟動 App 生效**（啟動時依偏好決定 ModelContainer 是否掛 CloudKit，不做執行期熱切換）。 |
| 通知（Local 推播） | 通知權限狀態 / 引導。權限被拒時導向系統設定。提醒時機固定為**到期當天**。 |
| 隱私權政策 | **App 內連結**，開啟託管網頁（GitHub Pages / 靜態頁）。另需將同一 URL 填入 App Store Connect 的 Privacy Policy URL（送審強制）。 |
| 版本 / 關於 | 顯示版本號等資訊。 |

### iCloud 決策紀錄
- 推翻 Spec「無感自動同步」：基於**尊重使用者自主權**，不在未經同意下背景上傳，改為**使用者掌控的 opt-in 開關**。
- 預設關 → 使用者主動開啟即為同意，**不需**首次啟動同意詢問，亦保住「無 Onboarding」。
- ⚠️ 待 `02-architecture` 處理：開/關同步時既有資料的遷移策略；圖片存 Documents 不被 CloudKit 自動備份的備份策略。

---

## 6. 導航流總覽

```
TabView
├─ 首頁 (NavigationStack)
│   ├─ 廣告（釘頂，無 fill 收合）
│   ├─ 現況甜甜圈 + 浪費統計（清除歷史）
│   ├─ 分桶清單（已過期未處理 / 3天內 / 保存期限內，可互動）
│   │   ├─ row 左右滑 / 長按 → 已使用 / 刪除 / 延長 / 丟棄
│   │   └─ row 單點          → push FoodFormView(.edit)
│   └─ ＋新增食材（底部填滿鈕）→ push FoodFormView(.add)
└─ 設定 (NavigationStack)
    ├─ 移除廣告      → IAP 購買 / Restore 流程
    ├─ iCloud 同步   → 開關（重啟生效）
    ├─ 通知          → 權限引導 / 導向系統設定
    ├─ 隱私權政策    → 開啟託管網頁
    └─ 版本 / 關於
```

### 通知點擊進入點
- 點擊到期通知 → 開啟 App 並**切到首頁 Tab**（該食材若仍 `active` 會自然出現在清單、且因已過期/當天到期排在最上方）。
- **v1 不深入定位到單一食材詳情**（首頁即編輯入口，且無獨立 detail 頁），保持簡單。未來要精準定位可用 deeplink（`mvvmc-navigation`）帶 food id。
- 由 AppRouter 統一處理通知 payload → 導航（`mvvmc-navigation` 集中式 Deeplink/推播路由）。

---

## 7. 交由後續 spec 的項目

- `02-architecture`：MVVMC 分層、SwiftData schema、CloudKit 同步與資料遷移、圖片儲存與備份、狀態判定演算法、IAP 實作。
- `03-screens`：各畫面 State / Action / UI 細節（Form 欄位驗證、空狀態文案、首頁統計卡片樣式、設定各列互動）。
- `04-tasks`：實作任務拆解。
