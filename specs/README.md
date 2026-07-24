# FoodEntropy Specs（規格索引）

本專案採 **Spec-Driven Development（SDD）**：規格是唯一真實來源，程式碼由規格推導而來。
不使用第三方 SDD 工具，所有規格以本目錄下的 markdown 文件維護，全部討論定案後才實作。

## 上游文件

- `archive/Spec.md` — 產品規格 v1（PRD，原始種子，**已被本目錄取代**，僅供緣起參考）

## SDD 流程

```
Spec.md（產品規格）
   ↓
00 專案憲章      不可違反前提：平台、架構、語言、依賴
   ↓
01 導航結構      決定 Tab、畫面清單、導航流
   ↓
02 技術架構      MVVMC 分層、SwiftData schema、CloudKit、圖片儲存
   ↓
03 逐畫面規格    每個畫面的 State / Action / UI 行為
   ↓
04 任務拆解      可依序實作的 tasks
   ↓
實作
```

## 規格清單與狀態

| # | 檔案 | 主題 | 狀態 |
|---|---|---|---|
| 00 | `00-constitution.md` | 專案憲章（平台 / 架構 / 語言 / 依賴） | ✅ 定案 |
| 01 | `01-navigation.md` | 導航結構 / Tab / 畫面清單 | ✅ 定案 |
| 02 | `02-architecture.md` | 技術架構 / 資料模型 | ✅ 定案 |
| 03 | `03-screens/form.md` | 食材 Form（新增/編輯） | ✅ 定案 |
| 03 | `03-screens/home.md` | 首頁（統計 + 分桶清單，單頁；已併入分析） | ✅ 定案 |
| 03 | `03-screens/analytics.md` | 分析（🗄️ v1.0.0 已併入首頁） | 🗄️ 已合併 |
| 03 | `03-screens/settings.md` | 設定 | ✅ 定案 |
| 04 | `04-tasks.md` | 實作任務拆解 | ✅ 定案 |

狀態圖例：⬜ 未開始 · 🚧 討論中 · ✅ 定案
