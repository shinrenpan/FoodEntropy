import Foundation
import Testing
@testable import FoodEntropy

// 動作完成後給 Siri 的回饋呈現（見 app-intents）。
// 只測不隨語言變動的部分——符號與「是否已離開清單」；
// 文案本身走 String Catalog，斷言譯文等於把翻譯釘進測試。
struct FoodItemActionOutcomeTests {

    @Test("每種結果有各自可辨識的符號")
    func symbolsAreDistinct() {
        let all = FoodItemActionOutcome.allCases
        let symbols = Set(all.map(\.symbolName))
        #expect(symbols.count == all.count)
        #expect(!symbols.contains(""))
    }

    /// 已使用／丟棄會讓食材離開清單，延長與新增不會。
    /// snippet 靠這個決定要不要顯示剩餘天數——已離開的食材顯示天數沒有意義。
    @Test("只有已使用與丟棄算作離開清單", arguments: [
        (FoodItemActionOutcome.consumed, true),
        (FoodItemActionOutcome.wasted, true),
        (FoodItemActionOutcome.extended, false),
        (FoodItemActionOutcome.added, false),
    ])
    func leavesListFlag(outcome: FoodItemActionOutcome, expected: Bool) {
        #expect(outcome.leavesList == expected)
    }
}
