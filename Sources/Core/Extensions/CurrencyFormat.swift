import Foundation

// 金額顯示的單一格式化入口（localization：金額交由系統格式化，不自行組字串）。
extension Double {
    /// 依 locale 的貨幣格式化。
    ///
    /// 取不到貨幣資訊時（例如 `Locale(identifier: "en")` 這類無地區的 locale）
    /// 退為純數字，**不 fallback 到任何硬編幣別**——顯示錯誤的貨幣符號會讓使用者
    /// 誤判金額量級，比不顯示符號更糟，而且無法從畫面分辨是否出錯。
    /// 小數位數為 0…2：本 app 的金額由使用者手動輸入，不是系統算出的價格——
    /// 輸入 99 就顯示 99，補一個 .00 是在顯示他沒輸入的精度（台幣尤其無感）。
    /// 代價是美元輸入整數時顯示 $12 而非慣例的 $12.00，換取忠實反映輸入值。
    func currencyText(locale: Locale = .current) -> String {
        let precision: NumberFormatStyleConfiguration.Precision = .fractionLength(0...2)
        guard let code = locale.currency?.identifier else {
            return formatted(.number.precision(precision).locale(locale))
        }
        return formatted(.currency(code: code).precision(precision).locale(locale))
    }

    /// VoiceOver 朗讀用：以完整幣別名稱取代符號。
    ///
    /// 視覺上 TWD 顯示為 `$`（台灣本地慣例），但 VoiceOver 會把 `$` 唸成「美金」——
    /// 對台灣使用者是錯的幣別。朗讀改用 `.fullName`（「99元」／「99 US dollars」），
    /// 視覺呈現則維持簡潔的符號形式。
    func currencyAccessibilityText(locale: Locale = .current) -> String {
        let precision: NumberFormatStyleConfiguration.Precision = .fractionLength(0...2)
        guard let code = locale.currency?.identifier else {
            return formatted(.number.precision(precision).locale(locale))
        }
        return formatted(.currency(code: code).presentation(.fullName).precision(precision).locale(locale))
    }
}
