import StoreKit

// IAP 資料層（02-architecture §7）。StoreKit 2「移除廣告」非消耗型購買。
// 單一 entitlement 真相來源：`adsRemoved` 由 `Transaction.currentEntitlements` 推導，不自存旗標。
@MainActor
final class StoreManager {
    static let removeAdsProductID = "com.shinrenpan.FoodEntropy.removeads"

    /// 是否已持有「移除廣告」entitlement（退款 / 撤銷會反映）。
    private(set) var adsRemoved: Bool

    /// 「移除廣告」商品（載入後才有價格）。
    private(set) var removeAdsProduct: Product?

    private var updatesTask: Task<Void, Never>?

    /// - Parameter adsRemoved: 供測試 / 預覽注入初始狀態；正式流程由 `start()` 對帳。
    init(adsRemoved: Bool = false) {
        self.adsRemoved = adsRemoved
    }

    /// App 啟動時呼叫：監聽交易更新、載入商品、對帳 entitlement。
    func start() async {
        listenForTransactionUpdates()
        await refreshProducts()
        await refreshEntitlements()
    }

    func refreshProducts() async {
        removeAdsProduct = try? await Product.products(for: [Self.removeAdsProductID]).first
    }

    /// 以 `currentEntitlements` 對帳是否持有（撤銷 / 退款會使其消失）。
    func refreshEntitlements() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else { continue }
            if transaction.productID == Self.removeAdsProductID, transaction.revocationDate == nil {
                owned = true
            }
        }
        adsRemoved = owned
    }

    /// 發起購買。回傳購買後是否已持有。
    func purchaseRemoveAds() async throws -> Bool {
        guard let product = removeAdsProduct else { return false }
        let result = try await product.purchase()
        switch result {
        case let .success(verification):
            guard case let .verified(transaction) = verification else { return false }
            await transaction.finish()
            await refreshEntitlements()
            return adsRemoved
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    /// 還原購買：向 App Store 同步後重新對帳。
    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    private func listenForTransactionUpdates() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard case let .verified(transaction) = update else { continue }
                await transaction.finish()
                await self?.refreshEntitlements()
            }
        }
    }
}
