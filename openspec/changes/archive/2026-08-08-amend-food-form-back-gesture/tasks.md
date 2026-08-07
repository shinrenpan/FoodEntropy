## 1. 規格修正

- [x] 1.1 修改 requirement「Leaving with unsaved changes asks first, and leaving unchanged does not」，把適用範圍限定為 app 自己的返回控制項；驗證：三個 scenario 的 WHEN 皆明指「the app's back control」，不再泛指離開。
- [x] 1.2 新增 requirement「The system back gesture leaves without prompting, by design」記錄系統手勢返回的刻意行為；驗證：requirement 說明不攔截、不停用手勢，並要求 `navigation` 的手勢條件維持不含畫面級分支。
- [x] 1.3 確認 `navigation` 的手勢判斷未含畫面級例外；驗證：`AppRouter.gestureRecognizerShouldBegin` 僅檢查 `nav.viewControllers.count > 1` 與 `topViewController?.appTransitionStyle == .push`，無任何針對特定 view controller 型別的分支。
- [x] 1.4 確認表單未自行停用互動式返回手勢；驗證：`grep -n "interactivePopGestureRecognizer\|interactiveContentPopGestureRecognizer" Sources/Features/FoodForm/` 無結果。

## 2. 收尾

- [x] 2.1 執行 `spectra validate amend-food-form-back-gesture`；驗證：指令回傳成功、無 error。
- [x] 2.2 archive 後確認 `openspec/specs/food-form-ui/spec.md` 已套用兩處變更；驗證：既有 requirement 的 scenario 含「the app's back control」，且新 requirement 已存在。
- [x] 2.3 勾銷 `baseline-food-form-ui` 中待實機確認的 task 2.3，註明結論為刻意設計；驗證：該 task 已標記完成並附結論。
