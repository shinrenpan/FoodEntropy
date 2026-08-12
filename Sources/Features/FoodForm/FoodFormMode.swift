import Foundation

// 新增 / 編輯共用 Form 的模式（見 food-form-ui）。
enum FoodFormMode: Equatable, Sendable {
    case add
    case edit(FoodItem)
}
