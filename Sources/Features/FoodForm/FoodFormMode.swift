import Foundation

// 新增 / 編輯共用 Form 的模式（03-screens/form.md）。
enum FoodFormMode: Equatable, Sendable {
    case add
    case edit(FoodItem)
}
