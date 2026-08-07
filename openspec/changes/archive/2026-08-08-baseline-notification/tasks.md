## 1. Baseline 文件化

- [x] 1.1 從 `NotificationService.fireHour`、`makeRequest` 的 identifier 與內容寫出 requirement「One notification per item, fired at nine in the morning on its expiry day」；驗證：`fireHour` 為 9、identifier 取自 `food.id.uuidString`、標題與內文皆以 `String(localized:)` 取得（第 91–92 行）。
- [x] 1.2 從 `reconcile(activeFoods:immediateTestFire:)` 與其四個呼叫端寫出 requirement「Scheduling is reconciled by rebuilding, not by tracking individual changes」；驗證：`reconcile` 首行為 `center.removeAllPendingNotificationRequests()`，且 `grep -rn "reconcile" Sources` 顯示呼叫端為 `SceneDelegate`（前景）、`HomeViewModel`、`FoodFormViewModel`——無任何逐筆 `removePendingNotificationRequests(withIdentifiers:)` 呼叫。
- [x] 1.3 從 `maxScheduled` 與排程管線的 `.sorted { $0.1 < $1.1 }.prefix(...)` 寫出 requirement「Scheduling respects the system limit by preferring the soonest expiries」；驗證：`maxScheduled` 為 60（低於 iOS 的 64），且排序在 `prefix` 之前。
- [x] 1.4 從 `compactMap` 內的 `fire > cutoff` 判斷寫出 requirement「Items whose fire time has already passed are not scheduled」；驗證：Release 路徑的 `cutoff` 為 `Date.now`，觸發時間不晚於現在者被濾除。
- [x] 1.5 從 `FoodFormViewModel` 儲存流程的 `requestAuthorizationIfNeeded()` 與 `requestAuthorizationIfNeeded` 內的狀態判斷寫出 requirement「Notification permission is requested at the first save, and only when undecided」；驗證：`FoodFormViewModel.swift:128` 在儲存路徑呼叫該方法，且該方法內僅在 `authorizationStatus() == .notDetermined` 時呼叫 `center.requestAuthorization`；`provisional` 與 `ephemeral` 於 `authorizationStatus()` 中歸入 `.authorized`。
- [x] 1.6 從 `SettingsViewModel.notificationDidTap` 的三態分流寫出 requirement「Once permission is decided, the app directs the user to system settings」；驗證：`notDetermined` 分支呼叫 `requestAuthorizationIfNeeded()`，`denied` 與 `authorized` 分支發出 `onRoute?(.openNotificationSettings)`。
- [x] 1.7 從 `makeRequest` 的 `content.userInfo` 與 `SceneDelegate` 的 `willPresent` 回呼寫出 requirement「Notifications carry a deeplink payload and are shown even in the foreground」；驗證：`userInfo` 帶 `["deeplink": "foodentropy://home"]`，且 `willPresent` 的 completion 回傳 `[.banner, .sound]`。
- [x] 1.8 從 `reconcile` 內 `shortTrigger` / `cutoff` 的編譯條件寫出 requirement「The immediate-fire test mode exists only in debug builds」；驗證：`immediateTestFire` 造成的行為差異全部落在 `#if DEBUG` / `#else` 區塊內（第 59–65 行），Release 分支硬編 `shortTrigger = false`、`cutoff = Date.now`；且 `SceneDelegate` 的前景對帳未傳入該參數（採預設 `false`）。
- [x] 1.9 從 `init(active:)` 與各方法開頭的 `guard active` 寫出 requirement「The service can be constructed inactive for testing」；驗證：`authorizationStatus`、`requestAuthorizationIfNeeded`、`reconcile` 三個方法皆以 `guard active` 開頭。

## 2. 收尾

- [x] 2.1 執行 `spectra validate baseline-notification`；驗證：指令回傳成功、無 error。
- [x] 2.2 archive 後補上 `openspec/specs/notification/spec.md` 的 `## Purpose` 段；驗證：`grep -c "TBD" openspec/specs/notification/spec.md` 為 0。
