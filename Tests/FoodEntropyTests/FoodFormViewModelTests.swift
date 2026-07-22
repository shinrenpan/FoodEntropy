import Foundation
import Testing
@testable import FoodEntropy

@MainActor
struct FoodFormViewModelTests {
    private func makeManager() throws -> SwiftDataManager {
        try SwiftDataManager(inMemory: true)
    }

    private let d0 = Date(timeIntervalSince1970: 1_700_000_000)
    private func day(_ n: Int, from base: Date) -> Date {
        base.addingTimeInterval(86_400 * Double(n))
    }

    // MARK: - 初始化

    @Test
    func `edit 模式帶入既有食材值`() async throws {
        let manager = try makeManager()
        let item = manager.create(name: "牛奶", purchaseDate: d0, expiryDate: day(3, from: d0))
        let vm = FoodFormViewModel(mode: .edit(item), manager: manager)
        #expect(vm.state.name == "牛奶")
        #expect(vm.state.purchaseDate == d0)
        #expect(vm.state.expiryDate == day(3, from: d0))
        #expect(vm.navigationTitle == "編輯食材")
    }

    @Test
    func `add 模式標題為新增食材`() async throws {
        let vm = try FoodFormViewModel(mode: .add, manager: makeManager())
        #expect(vm.navigationTitle == "新增食材")
    }

    // MARK: - 驗證

    @Test
    func `名稱去空白後為空則不可儲存`() async throws {
        let vm = try FoodFormViewModel(mode: .add, manager: makeManager())
        vm.state.name = "   "
        #expect(vm.state.isSaveEnabled == false)
        vm.state.name = "牛奶"
        #expect(vm.state.isSaveEnabled == true)
    }

    // MARK: - 到期日不得早於購買日

    @Test
    func `購買日改到晚於到期日時頂推到期日`() async throws {
        let manager = try makeManager()
        let item = manager.create(name: "A", purchaseDate: d0, expiryDate: day(3, from: d0))
        let vm = FoodFormViewModel(mode: .edit(item), manager: manager)
        await vm.doAction(.view(.purchaseDateChanged(day(5, from: d0))))
        #expect(vm.state.purchaseDate == day(5, from: d0))
        #expect(vm.state.expiryDate == day(5, from: d0))   // 被頂推
    }

    @Test
    func `購買日仍早於到期日時不動到期日`() async throws {
        let manager = try makeManager()
        let item = manager.create(name: "A", purchaseDate: d0, expiryDate: day(3, from: d0))
        let vm = FoodFormViewModel(mode: .edit(item), manager: manager)
        await vm.doAction(.view(.purchaseDateChanged(day(1, from: d0))))
        #expect(vm.state.expiryDate == day(3, from: d0))   // 不變
    }

    // MARK: - 儲存

    @Test
    func `add 儲存後 manager 新增一筆`() async throws {
        let manager = try makeManager()
        let vm = FoodFormViewModel(mode: .add, manager: manager)
        vm.state.name = "  牛奶  "   // 去空白後存
        vm.state.purchaseDate = d0
        vm.state.expiryDate = day(3, from: d0)
        await vm.doAction(.view(.saveDidTap))
        let items = manager.fetchActiveFoods()
        #expect(items.count == 1)
        #expect(items.first?.name == "牛奶")
    }

    @Test
    func `edit 儲存後 manager 更新既有筆`() async throws {
        let manager = try makeManager()
        let item = manager.create(name: "舊", purchaseDate: d0, expiryDate: day(3, from: d0))
        let vm = FoodFormViewModel(mode: .edit(item), manager: manager)
        vm.state.name = "新"
        await vm.doAction(.view(.saveDidTap))
        let items = manager.fetchActiveFoods()
        #expect(items.count == 1)
        #expect(items.first?.name == "新")
    }

    @Test
    func `名稱為空時儲存不寫入`() async throws {
        let manager = try makeManager()
        let vm = FoodFormViewModel(mode: .add, manager: manager)
        vm.state.name = "   "
        await vm.doAction(.view(.saveDidTap))
        #expect(manager.fetchActiveFoods().isEmpty)
    }

    // MARK: - 放棄變更

    @Test
    func `未變更時返回不跳確認`() async throws {
        let manager = try makeManager()
        let item = manager.create(name: "A", purchaseDate: d0, expiryDate: day(3, from: d0))
        let vm = FoodFormViewModel(mode: .edit(item), manager: manager)
        await vm.doAction(.view(.dismissDidTap))
        #expect(vm.state.showDiscardConfirm == false)
    }

    @Test
    func `有變更時返回跳確認`() async throws {
        let manager = try makeManager()
        let item = manager.create(name: "A", purchaseDate: d0, expiryDate: day(3, from: d0))
        let vm = FoodFormViewModel(mode: .edit(item), manager: manager)
        vm.state.name = "改了"
        await vm.doAction(.view(.dismissDidTap))
        #expect(vm.state.showDiscardConfirm == true)
    }

    @Test
    func `取消放棄關閉確認`() async throws {
        let vm = try FoodFormViewModel(mode: .add, manager: makeManager())
        vm.state.showDiscardConfirm = true
        await vm.doAction(.view(.discardCancelled))
        #expect(vm.state.showDiscardConfirm == false)
    }

    // MARK: - 圖片

    @Test
    func `imagePicked 設定 removeImage 清除`() async throws {
        let vm = try FoodFormViewModel(mode: .add, manager: makeManager())
        let data = Data([0x01, 0x02])
        await vm.doAction(.view(.imagePicked(data)))
        #expect(vm.state.imageData == data)
        await vm.doAction(.view(.removeImage))
        #expect(vm.state.imageData == nil)
    }
}
