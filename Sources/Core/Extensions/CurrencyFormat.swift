import Foundation

// 金額顯示的單一格式化入口（localization：金額交由系統格式化，不自行組字串）。
extension Double {
    /// 依 locale 的貨幣格式化。
    ///
    /// 取不到貨幣資訊時（例如 `Locale(identifier: "en")` 這類無地區的 locale）
    /// 退為純數字，**不 fallback 到任何硬編幣別**——顯示錯誤的貨幣符號會讓使用者
    /// 誤判金額量級，比不顯示符號更糟，而且無法從畫面分辨是否出錯。
    func currencyText(locale: Locale = .current) -> String {
        guard let code = locale.currency?.identifier else {
            return formatted(.number.locale(locale))
        }
        return formatted(.currency(code: code).locale(locale))
    }
}
