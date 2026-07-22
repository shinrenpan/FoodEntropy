import Testing
@testable import FoodEntropy

// Phase 0 佔位測試，確認測試 target 可編譯執行。
// 正式 ViewModel 測試依 mvvmc-testing（doAction 注入）於各 Feature phase 撰寫。
struct FoodEntropyTests {
    @Test
    func placeholder() {
        #expect(Bool(true))
    }
}
