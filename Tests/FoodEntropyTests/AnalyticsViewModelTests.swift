import Foundation
import Testing
@testable import FoodEntropy

@MainActor
struct AnalyticsViewModelTests {
    private func makeVM() throws -> (AnalyticsViewModel, SwiftDataManager) {
        let manager = try SwiftDataManager(inMemory: true)
        return (AnalyticsViewModel(manager: manager), manager)
    }

    // FoodItem.mocks 效期偏移：-2（expired）/ 0、+3（nearExpiry）/ +10（fresh）
    @Test
    func `foodsLoaded 依效期分三桶`() async throws {
        let (vm, _) = try makeVM()
        await vm.doAction(.dataResponse(.foodsLoaded(FoodItem.mocks)))
        #expect(vm.state.expired.count == 1)
        #expect(vm.state.nearExpiry.count == 2)
        #expect(vm.state.fresh.count == 1)
    }

    @Test
    func `空清單三桶皆空`() async throws {
        let (vm, _) = try makeVM()
        await vm.doAction(.dataResponse(.foodsLoaded([])))
        #expect(vm.state.expired.isEmpty)
        #expect(vm.state.nearExpiry.isEmpty)
        #expect(vm.state.fresh.isEmpty)
    }

    @Test
    func `onAppear 從 manager 載入並分桶`() async throws {
        let (vm, manager) = try makeVM()
        let now = Date.now
        let cal = Calendar.current
        manager.create(name: "過期", purchaseDate: now, expiryDate: cal.date(byAdding: .day, value: -2, to: now)!)
        manager.create(name: "快到", purchaseDate: now, expiryDate: cal.date(byAdding: .day, value: 1, to: now)!)
        manager.create(name: "還早", purchaseDate: now, expiryDate: cal.date(byAdding: .day, value: 10, to: now)!)
        await vm.doAction(.view(.onAppear))
        #expect(vm.state.expired.count == 1)
        #expect(vm.state.nearExpiry.count == 1)
        #expect(vm.state.fresh.count == 1)
    }
}
