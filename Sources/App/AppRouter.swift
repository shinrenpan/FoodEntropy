import UIKit

// MARK: - TransitionStyle

extension AppRouter {
    enum TransitionStyle: Equatable {
        case push
        case modal
        case fade
        case sheet
    }
}

// MARK: - UIViewController + appTransitionStyle

private final class TransitionStyleBox {
    let style: AppRouter.TransitionStyle
    init(_ style: AppRouter.TransitionStyle) { self.style = style }
}

// 僅作為 associated object 的位址使用、從不真正被改寫，故 nonisolated(unsafe) 安全（Swift 6）
private nonisolated(unsafe) var appTransitionStyleKey: UInt8 = 0

extension UIViewController {
    // internal 而非 fileprivate：導航的返回行為取決於這個標記，
    // 而「以 resetTo 抵達的畫面其返回行為是否與 push 一致」必須測得到。
    // 仍限於本模組內，未對外公開。
    var appTransitionStyle: AppRouter.TransitionStyle {
        get { (objc_getAssociatedObject(self, &appTransitionStyleKey) as? TransitionStyleBox)?.style ?? .push }
        set { objc_setAssociatedObject(self, &appTransitionStyleKey, TransitionStyleBox(newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

// MARK: - AppRouter

// 唯一導航中樞（mvvmc-navigation）。Stateless：不持有 nav / window / VC，
// 一律從 source.navigationController 動態取得。
@MainActor
final class AppRouter: NSObject {
    static let shared = AppRouter()
    private override init() {}

    func to(
        _ destination: UIViewController,
        from source: UIViewController,
        style: TransitionStyle = .push,
        animated: Bool = true
    ) {
        guard let nav = source.navigationController else {
            assertionFailure("AppRouter.to(): source VC 沒有 navigationController，請確認 rootViewController 為 UINavigationController")
            return
        }
        attach(to: nav)
        destination.appTransitionStyle = style
        nav.pushViewController(destination, animated: animated)
    }

    /// 回到 stack 根部並呈現目標，以**單次** stack 設定完成。
    ///
    /// 不可拆成「先 pop 回根、再 push」兩次呼叫：UIKit 會丟棄前一次導航
    /// 尚未落定期間的 push，結果是 pop 生效、push 消失——使用者被彈回
    /// 首頁而目標從未出現，且沒有任何錯誤徵兆（見 fix-deeplink-dropped-push）。
    ///
    /// 只有 deeplink 需要這條路徑：它是唯一會在「畫面上可能是任何東西」
    /// 的情況下觸發導航的入口，其餘導航都由當前畫面自己發起。
    func resetTo(
        _ destination: UIViewController,
        from source: UIViewController,
        style: TransitionStyle = .push,
        animated: Bool = true
    ) {
        guard let nav = source.navigationController else {
            assertionFailure("AppRouter.resetTo(): source VC 沒有 navigationController，請確認 rootViewController 為 UINavigationController")
            return
        }
        guard let root = nav.viewControllers.first else {
            assertionFailure("AppRouter.resetTo(): navigation stack 是空的，沒有可回歸的根部")
            return
        }
        attach(to: nav)
        destination.appTransitionStyle = style
        nav.setViewControllers([root, destination], animated: animated)
    }

    /// 轉場與返回手勢的接管設定。`to` 與 `resetTo` 共用，
    /// 否則以 `resetTo` 抵達的畫面其返回行為會與其他畫面不一致。
    private func attach(to nav: UINavigationController) {
        guard nav.delegate !== self else { return }
        nav.delegate = self
        nav.interactivePopGestureRecognizer?.isEnabled = true
        nav.interactivePopGestureRecognizer?.delegate = self
        if #available(iOS 26, *) {
            nav.interactiveContentPopGestureRecognizer?.isEnabled = true
            nav.interactiveContentPopGestureRecognizer?.delegate = self
        }
    }

    func back(from source: UIViewController, animated: Bool = true) {
        // 堆疊裡還有前一個畫面 → pop，且這一步必須先判斷。
        //
        // 被 push 到「呈現式堆疊」上的畫面（例如分桶清單 sheet 內的編輯表單）
        // 自己的樣式是 .push，若直接往上採用 nav 的樣式（.sheet），返回會變成
        // 收掉整個 sheet 而不是回到前一頁。下方那段 fallback 是為「整個 nav 被
        // 呈現出來、而 source 是它的根畫面」寫的，對疊在根上面的畫面不成立。
        if source.appTransitionStyle == .push,
           let nav = source.navigationController,
           nav.viewControllers.count > 1 {
            nav.popViewController(animated: animated)
            return
        }
        let style = source.appTransitionStyle != .push
            ? source.appTransitionStyle
            : source.navigationController?.appTransitionStyle ?? .push
        switch style {
        case .sheet:
            (source.navigationController ?? source).dismiss(animated: animated)
        default:
            guard let nav = source.navigationController else {
                assertionFailure("AppRouter.back(): source VC 沒有 navigationController")
                return
            }
            nav.popViewController(animated: animated)
        }
    }

    func backTo(_ destination: UIViewController, from source: UIViewController, animated: Bool = true) {
        guard let nav = source.navigationController else {
            assertionFailure("AppRouter.backTo(): source VC 沒有 navigationController")
            return
        }
        nav.popToViewController(destination, animated: animated)
    }

    func backToRoot(from source: UIViewController, animated: Bool = true) {
        guard let nav = source.navigationController else {
            assertionFailure("AppRouter.backToRoot(): source VC 沒有 navigationController")
            return
        }
        nav.popToRootViewController(animated: animated)
    }

    func sheet(
        _ destination: UIViewController,
        from source: UIViewController,
        detents: [UISheetPresentationController.Detent]? = nil,
        animated: Bool = true
    ) {
        destination.appTransitionStyle = .sheet
        destination.modalPresentationStyle = .pageSheet
        if let detents {
            destination.sheetPresentationController?.detents = detents
        }
        source.present(destination, animated: animated)
    }

    func deeplink(_ destination: UIViewController, animated: Bool = true) {
        let rootVC = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.rootViewController
        guard let rootVC else {
            assertionFailure("AppRouter.deeplink(): 找不到 rootViewController")
            return
        }
        destination.appTransitionStyle = .sheet
        destination.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak destination] _ in
                destination?.dismiss(animated: true)
            }
        )
        let nav = UINavigationController(rootViewController: destination)
        nav.modalPresentationStyle = .fullScreen
        rootVC.present(nav, animated: animated)
    }
}

// MARK: - UINavigationControllerDelegate

extension AppRouter: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        let style = operation == .push ? toVC.appTransitionStyle : fromVC.appTransitionStyle
        guard style != .push, style != .sheet else { return nil }
        return AppTransitionAnimator(style: style, isPush: operation == .push)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension AppRouter: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let nav = gestureRecognizer.view?.next as? UINavigationController else { return true }
        guard nav.viewControllers.count > 1 else { return false }
        return (nav.topViewController?.appTransitionStyle ?? .push) == .push
    }
}

// MARK: - AppTransitionAnimator

private final class AppTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let style: AppRouter.TransitionStyle
    let isPush: Bool

    init(style: AppRouter.TransitionStyle, isPush: Bool) {
        self.style = style
        self.isPush = isPush
    }

    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval { 0.35 }

    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        switch style {
        case .modal: animateModal(transitionContext)
        case .fade: animateFade(transitionContext)
        case .push, .sheet: transitionContext.completeTransition(true)
        }
    }
}

private extension AppTransitionAnimator {
    func animateModal(_ ctx: any UIViewControllerContextTransitioning) {
        let duration = transitionDuration(using: ctx)
        if isPush {
            guard let toVC = ctx.viewController(forKey: .to), let toView = ctx.view(forKey: .to) else {
                ctx.completeTransition(false); return
            }
            let finalFrame = ctx.finalFrame(for: toVC)
            toView.frame = finalFrame.offsetBy(dx: 0, dy: finalFrame.height)
            ctx.containerView.addSubview(toView)
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
                toView.frame = finalFrame
            } completion: { _ in
                ctx.completeTransition(!ctx.transitionWasCancelled)
            }
        } else {
            guard let fromVC = ctx.viewController(forKey: .from),
                  let fromView = ctx.view(forKey: .from),
                  let toView = ctx.view(forKey: .to) else {
                ctx.completeTransition(false); return
            }
            ctx.containerView.insertSubview(toView, belowSubview: fromView)
            let initialFrame = ctx.initialFrame(for: fromVC)
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn) {
                fromView.frame = initialFrame.offsetBy(dx: 0, dy: initialFrame.height)
            } completion: { _ in
                ctx.completeTransition(!ctx.transitionWasCancelled)
            }
        }
    }

    func animateFade(_ ctx: any UIViewControllerContextTransitioning) {
        let duration = transitionDuration(using: ctx)
        if isPush {
            guard let toView = ctx.view(forKey: .to) else { ctx.completeTransition(false); return }
            toView.alpha = 0
            ctx.containerView.addSubview(toView)
            UIView.animate(withDuration: duration) {
                toView.alpha = 1
            } completion: { _ in
                ctx.completeTransition(!ctx.transitionWasCancelled)
            }
        } else {
            guard let fromView = ctx.view(forKey: .from),
                  let toView = ctx.view(forKey: .to) else {
                ctx.completeTransition(false); return
            }
            ctx.containerView.insertSubview(toView, belowSubview: fromView)
            UIView.animate(withDuration: duration) {
                fromView.alpha = 0
            } completion: { _ in
                ctx.completeTransition(!ctx.transitionWasCancelled)
            }
        }
    }
}
