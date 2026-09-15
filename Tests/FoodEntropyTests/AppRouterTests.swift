import Testing
import UIKit
@testable import FoodEntropy

// AppRouter 的導航結果測試（fix-deeplink-dropped-push）。
//
// 專案其餘測試都是純 Swift 的 ViewModel 測試，這組刻意碰 UIKit：
// 本 change 要修的缺陷，其表現是「畫面看起來完全正常」（停在首頁）
// 而目標從未被呈現。截圖抓不到那種失敗，只有斷言 stack 內容抓得到。
//
// 不需要 window 或 scene，只建立 navigation controller 並讀 viewControllers。
@MainActor
struct AppRouterTests {
    private func makeNav(depth: Int) -> (UINavigationController, UIViewController) {
        let root = UIViewController()
        let nav = UINavigationController(rootViewController: root)
        // 無 window 時 UIKit 會把轉場延後，viewControllers 不同步更新。
        // 載入 view 後 navigation controller 才會如實機般立即反映 stack 變更。
        nav.loadViewIfNeeded()
        for _ in 1..<max(depth, 1) {
            nav.pushViewController(UIViewController(), animated: false)
        }
        return (nav, root)
    }

    // MARK: - resetTo：不論起始深度，結果恆為「根部 + 目標」

    // 以 animated: false 驗證：無 window 的測試環境下 UIKit 會把帶動畫的轉場延後，
    // viewControllers 不同步更新，斷任何 stack 內容都只會測到 UIKit 的排程而非本方法。
    // 這組測試釘的是**契約**——不論起始深度，結果恆為「根部 + 目標」。
    // 帶動畫時「push 被丟棄」的那一面無法在此涵蓋，由模擬器實機驗證負責
    // （見 tasks 3.1，記錄真實 stack 內容而非截圖）。
    @Test
    func `從根部呼叫 resetTo 後只剩根部與目標`() async throws {
        let (nav, root) = makeNav(depth: 1)
        let destination = UIViewController()
        AppRouter.shared.resetTo(destination, from: root, animated: false)
        #expect(nav.viewControllers.count == 2)
        #expect(nav.viewControllers.first === root)
        #expect(nav.viewControllers.last === destination)
    }

    @Test
    func `已推著一層時呼叫 resetTo 後只剩根部與目標`() async throws {
        let (nav, root) = makeNav(depth: 2)
        let destination = UIViewController()
        AppRouter.shared.resetTo(destination, from: root, animated: false)
        // 缺陷的原始表現是停在只剩根部的狀態——這裡明確排除它。
        #expect(nav.viewControllers.count == 2)
        #expect(nav.viewControllers.first === root)
        #expect(nav.viewControllers.last === destination)
    }

    @Test
    func `已推著兩層時呼叫 resetTo 後只剩根部與目標`() async throws {
        let (nav, root) = makeNav(depth: 3)
        let destination = UIViewController()
        AppRouter.shared.resetTo(destination, from: root, animated: false)
        #expect(nav.viewControllers.count == 2)
        #expect(nav.viewControllers.first === root)
        #expect(nav.viewControllers.last === destination)
    }

    // MARK: - 轉場樣式：resetTo 抵達者必須與 push 抵達者一致

    // 返回鍵與邊緣返回手勢都依這個標記決定行為（見 navigation 的
    // 「arrival transition is recorded on the destination」）。不一致的話，
    // 以 deeplink 抵達的編輯表單會退不回去，或退法與從清單點進去時不同。
    @Test
    func `resetTo 抵達的目標帶有與 push 相同的轉場樣式`() async throws {
        let (_, root) = makeNav(depth: 1)

        let pushed = UIViewController()
        AppRouter.shared.to(pushed, from: root, animated: false)

        let (_, root2) = makeNav(depth: 2)
        let reset = UIViewController()
        AppRouter.shared.resetTo(reset, from: root2, animated: false)

        #expect(reset.appTransitionStyle == pushed.appTransitionStyle)
        #expect(reset.appTransitionStyle == .push)
    }

    // MARK: - back：呈現式堆疊內的 pop（restyle-home-as-card-stack）

    // 分桶清單以 sheet 呈現，編輯表單 push 在它自己的堆疊上。
    // 離開表單必須回到清單，不是收掉整個 sheet。
    @Test
    func `在呈現式堆疊內返回是 pop 而非收掉整個堆疊`() async throws {
        let root = UIViewController()
        let nav = UINavigationController(rootViewController: root)
        nav.loadViewIfNeeded()
        // 模擬「整個 nav 是被 sheet 呈現出來的」
        nav.appTransitionStyle = .sheet

        let pushed = UIViewController()
        AppRouter.shared.to(pushed, from: root, animated: false)
        #expect(nav.viewControllers.count == 2)

        AppRouter.shared.back(from: pushed, animated: false)
        // 回到清單：堆疊只剩根，而不是整個 nav 被 dismiss
        #expect(nav.viewControllers.count == 1)
        #expect(nav.viewControllers.first === root)
    }

    @Test
    func `呈現式堆疊的根畫面返回仍是收掉整個堆疊`() async throws {
        let root = UIViewController()
        let nav = UINavigationController(rootViewController: root)
        nav.loadViewIfNeeded()
        nav.appTransitionStyle = .sheet
        // 根畫面沒有前一頁可退 → 維持既有行為（收掉整個 nav），不應 pop
        AppRouter.shared.back(from: root, animated: false)
        #expect(nav.viewControllers.count == 1)
    }
}
