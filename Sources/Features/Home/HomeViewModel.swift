import Foundation

@Observable
@MainActor
final class HomeViewModel {
    enum Action: Sendable {
        case view(ViewAction)
        case dataResponse(DataResponse)
    }

    static let wasteWindowDays = 30   // 浪費率統計視窗

    var state: State = .init()

    @ObservationIgnored
    private let manager: SwiftDataManager

    @ObservationIgnored
    private let store: StoreManager

    @ObservationIgnored
    var onRoute: (@MainActor (Router) -> Void)?

    // 首頁不再持有 NotificationService：會改動 active 清單的動作全部移到
    // 分桶清單畫面，而清除歷史依規格不重建排程（見 home-ui）。
    init(manager: SwiftDataManager, store: StoreManager) {
        self.manager = manager
        self.store = store
    }

    func doAction(_ action: Action) async {
        switch action {
        case let .view(action): await handleViewAction(action)
        case let .dataResponse(response): await handleDataResponse(response)
        }
    }
}

// MARK: - ViewAction

extension HomeViewModel {
    enum ViewAction: Sendable {
        case onAppear
        case addDidTap
        case settingsDidTap             // 導覽列右上角齒輪
        case cardDidTap(HomeCard)       // 點卡片：移到最前面；已在最前面的非空分桶卡才開清單
        case clearHistoryDidTap            // 清除歷史統計 → 顯示確認
        case clearHistoryConfirmed
    }

    private func handleViewAction(_ action: ViewAction) async {
        switch action {
        case .onAppear:
            await reload()

        case .addDidTap:
            onRoute?(.toAdd)

        case .settingsDidTap:
            onRoute?(.toSettings)

        case let .cardDidTap(card):
            // 第一次點只把卡移到最前面。否則使用者無法單純瀏覽這疊卡——
            // 任何一次點擊都會被丟進 modal（見 home-ui 的卡片點擊 requirement）。
            let wasSelected = state.selectedCard == card
            state.selectedCard = card
            state.hasChosenCard = true
            // 已在最前面、是分桶卡、且該桶非空時才開清單。
            // 摘要卡與空桶點幾次都不開，卡面上也不會有開啟提示。
            guard wasSelected,
                  let bucket = card.bucket,
                  !state.items(in: bucket).isEmpty
            else { return }
            // 呈現清單是導航，不是狀態：由 HostController 以 AppRouter 執行
            // （見 navigation 的「ViewModel 發出意圖、HostController 執行」）。
            onRoute?(.toBucketList(bucket))

        case .clearHistoryDidTap:
            state.showClearHistoryConfirm = true

        case .clearHistoryConfirmed:
            try? manager.deleteResolvedFoods()
            state.showClearHistoryConfirm = false
            await reload()   // 統計歸零、清除鈕收起
        }
    }

    private func reload() async {
        let active = manager.fetchActiveFoods()
        let resolved = manager.fetchResolvedFoods()
        state.adsRemoved = store.adsRemoved   // 持有移除廣告 entitlement 時隱藏 AdSlotView
        await doAction(.dataResponse(.loaded(active: active, resolved: resolved)))
    }

}

// MARK: - Router

extension HomeViewModel {
    enum Router: Sendable {
        case toAdd
        // 設定不再是並列的 tab，改為推入同一個 stack（見 home-ui）。
        case toSettings
        // 分桶清單是獨立畫面：首頁改成卡片堆疊後不再渲染食材列（見 home-ui）。
        case toBucketList(ExpiryStatus)
    }
}

// MARK: - DataResponse

extension HomeViewModel {
    enum DataResponse: Sendable {
        case loaded(active: [FoodItem], resolved: [FoodItem])
    }

    private func handleDataResponse(_ response: DataResponse) async {
        switch response {
        case let .loaded(active, resolved):
            // 現況：依效期狀態分三桶（active 已依到期日升冪，桶內順序天然正確）。
            // 計算共用給 Widget——兩處顯示的數字必須相同，故邏輯只有一份。
            let summary = FoodStatusSummary(active: active)
            state.expired = summary.expired
            state.nearExpiry = summary.nearExpiry
            state.fresh = summary.fresh
            // 歷史統計：只計「近 30 天」內處理的（滾動視窗，舊資料自然不影響）。
            let cutoff = Calendar.current.date(byAdding: .day, value: -Self.wasteWindowDays, to: .now) ?? .distantPast
            let windowed = resolved.filter { ($0.resolvedAt ?? .distantPast) >= cutoff }
            state.consumedCount = windowed.filter { $0.status == .consumed }.count
            state.wastedCount = windowed.filter { $0.status == .wasted }.count
            // all-time：只要有任何已處理紀錄就露出清除鈕（含 30 天視窗外的舊資料）。
            state.hasHistory = !resolved.isEmpty
            // 金額：前瞻只取 nearExpiry（還來得及救），回顧沿用同一視窗。
            // 兩者皆以 nil 表示「無可計算」——畫面據此整行不渲染，而非顯示 0。
            state.upcomingExpiryCost = summary.upcomingExpiryCost
            state.wastedCost = FoodStatusSummary.sumPrices(windowed.filter { $0.status == .wasted })
            state.expiredCost = FoodStatusSummary.sumPrices(summary.expired)
            // 初始那一張依緊急度挑選；使用者一旦自己選過，重載就不再更動他的選擇。
            // 空桶是正當的選擇，不該因為「沒有內容」而被收回（見 home-ui）。
            if !state.hasChosenCard {
                state.selectedCard = state.mostUrgentNonEmptyCard
            }

        }
    }
}
