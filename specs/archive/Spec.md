> ⚠️ **此文件已被取代（僅供緣起參考）**
>
> 本文件為專案最初的「產品種子」，用於啟動 SDD 討論。**最新且唯一的真實來源是 [`specs/`](../)**（見 [`specs/README.md`](../README.md)）。
> 以下內容中，部分決策已在 SDD 討論中被推翻，**請勿再依本文件實作**：
>
> | 本文件原案 | 已更新為 | 依據 |
> |---|---|---|
> | iCloud 無感自動同步 | **opt-in 開關、預設關、重啟生效** | `specs/01-navigation.md` §6、`specs/02-architecture.md` §6 |
> | 圖片存 Documents 路徑 | **`@Attribute(.externalStorage)` + JPEG 壓縮** | `specs/02-architecture.md` §3 |
> | 統計功能列為「未來」 | **分析 Tab 納入首版**（唯讀分桶總覽） | `specs/01-navigation.md` §3、`specs/03-screens/analytics.md` |
> | 「已使用」單一狀態 | **擴充為 consumed / wasted** 兩種出口 | `specs/02-architecture.md` §2.3 |
> | 未定最低 iOS / 平台 | **iPhone only、iOS 26+、直向鎖定** | `specs/00-constitution.md` |
>
> 本文件保留是為了記錄產品緣起（PTT 痛點、命名概念、命名查核），不再作為實作依據。

---

# FoodEntropy（食熵）— 產品規格 v1

## 專案概述

一款食材效期管理 App，協助使用者記錄購買的食材、追蹤保存期限，並在到期時提醒使用者，減少因遺忘而造成的食物浪費。需求來源：PTT 鄉民討論串中提及的痛點（買菜/買肉常忘記煮、錯過賞味期限）。

- **英文名稱**：FoodEntropy
- **中文名稱**：食熵
- **命名概念**：借用物理學「熵」（entropy）的概念——放著不管的食材會隨時間推移逐漸「劣化/混亂」，呼應「不管理就會變糟」的核心訴求
- **命名查核**：已查證 App Store / Google Play 上無同名 app（FoodEntropy 無撞名；曾考慮的 FoodKeeper、KeepFresh、PantryPal、Fridgey、Chomp、Nomly 等均已被使用，故排除）

## 目標對象

一般消費者。非個人工具，需考慮陌生使用者的直覺操作與上架合規要求。

## 開發策略

**一次做到 Production 等級**，不採 MVP 快速迭代路線。所有下述「Production 必要項目」皆納入第一版範圍。

---

## 核心資料模型

| 欄位 | 說明 | 必填 |
|---|---|---|
| 食材名稱 | 使用者手動輸入 | 必填 |
| 購買日期 | 手動輸入，可給預設值（今天），供之後統計功能使用 | 必填 |
| 到期日期 | 手動輸入，可給預設值（例如今天+3天）方便選擇 | 必填 |
| 圖片 | 拍照或相簿選圖，未提供則顯示預設圖示 | 選填 |

**不做**：食材分類、系統自動推算保存期限、料理推薦功能、OCR/條碼掃描辨識。

---

## 核心功能

### 1. 食材列表
- 依到期日期排序（越早到期排越前）
- 快到期 / 已過期項目以顏色區分（例如黃色警示、紅色過期）

### 2. 效期提醒
- 使用 Local Notification（不需後端）
- 提醒時機：**到期當天**（不做自訂天數）

### 3. List Row 操作（滑動 / 長按選單）
- 刪除
- 標記已使用（從清單移除，保留紀錄供未來統計功能使用）
- 延長效期（修改到期日期）

### 4. 新增食材流程
- 手動輸入名稱 → 選擇/確認購買日期與到期日期 → 選填拍照或相簿選圖 → 儲存
- 無 Onboarding 引導流程，直接進入主畫面

---

## Production 必要項目

### 1. iCloud 備份
- 採用 SwiftData + CloudKit（`cloudKitDatabase` 設定），同步至使用者私有 iCloud container
- 使用者無感知，非帳號登入式同步，純背景備份
- 注意：圖片若存於 Documents 資料夾（而非 SwiftData 內建 blob），不會被此機制自動備份，需另外處理備份策略

### 2. 廣告整合
- 商業模式：免費 + 廣告（Google AdMob），付費一次性移除廣告
- 需處理 App Tracking Transparency（ATT）同意流程
- 若使用者拒絕個人化廣告追蹤，顯示非個人化廣告（合規但收益較低）

### 3. 隱私權合規
- 隱私權政策頁面（因使用相機、相簿、通知功能，App Store 審核會要求）
- App Privacy 標籤依實際資料蒐集情形填寫

### 4. 空狀態與錯誤處理
- 首次開啟無食材時的畫面設計
- 通知權限被拒絕時的引導提示文案
- 圖片載入失敗等基本錯誤處理

### 5. Crash Reporting / Analytics
- 採用蘋果內建工具：Xcode Organizer（Crash Reports）+ App Store Connect Analytics（下載量、留存率）
- 不額外整合第三方 SDK（如 Firebase），降低依賴與維運成本

---

## 技術棧

- **UI**：SwiftUI
- **資料儲存**：SwiftData（本地）+ CloudKit（iCloud 同步）
- **圖片儲存**：本地 Documents 資料夾，SwiftData 存路徑參照
- **提醒**：UserNotifications
- **圖片來源**：PhotosPicker（相簿選圖）+ 拍照（UIImagePickerController 或 PHPickerViewController）
- **廣告**：Google AdMob SDK
- **無**：帳號系統、自建後端、第三方 Analytics SDK

---

## 明確排除範圍（不做清單）

- 食材分類系統
- 系統依食材類型自動推算保存期限
- 料理推薦功能
- OCR / 條碼掃描辨識
- 多裝置即時協作同步（家庭共享）
- 特殊 Onboarding 引導流程
- 自訂提醒天數（統一為到期當天）

---

## 待確認事項（下一版討論）

- 畫面架構 / Tab 結構規劃
- App Store 上架素材（截圖、描述文案）
- App Privacy 標籤詳細填寫內容
- 隱私權政策頁面實作方式（靜態網頁 / GitHub Pages）
