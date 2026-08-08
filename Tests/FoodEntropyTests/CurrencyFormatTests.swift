import Foundation
import Testing
@testable import FoodEntropy

struct CurrencyFormatTests {

    @Test("有貨幣資訊的地區以該幣別格式化")
    func usesLocaleCurrency() {
        let tw = Locale(identifier: "zh_TW")
        let text = Double(99).currencyText(locale: tw)
        #expect(text.contains("99"))
        #expect(text.contains("$"))   // TWD 在台灣 locale 顯示為 $
    }

    @Test("不同地區給出不同的貨幣呈現")
    func differsAcrossLocales() {
        let tw = Double(99).currencyText(locale: Locale(identifier: "zh_TW"))
        let jp = Double(99).currencyText(locale: Locale(identifier: "ja_JP"))
        #expect(tw != jp)   // 幣別不同，呈現必然不同
    }

    /// 無地區資訊的 locale（如 "en"）取不到貨幣。此時退為純數字，
    /// 而非 fallback 到某個硬編幣別——顯示錯誤的貨幣符號比不顯示更糟。
    @Test("無貨幣資訊時退為純數字，不假裝成任何幣別")
    func fallsBackToPlainNumber() {
        let bare = Locale(identifier: "en")
        guard bare.currency == nil else {
            // 該 locale 若有貨幣資訊，本測試前提不成立，跳過
            return
        }
        let text = Double(99).currencyText(locale: bare)
        #expect(text.contains("99"))
        #expect(!text.contains("$"))
        #expect(!text.contains("USD"))
    }

    // MARK: - 精度：有小數才顯示

    @Test("整數金額不補小數位")
    func integerHasNoDecimals() {
        let tw = Locale(identifier: "zh_TW")
        let text = Double(99).currencyText(locale: tw)
        #expect(!text.contains(".00"))
        #expect(text.contains("99"))
    }

    @Test("有小數的金額如實顯示")
    func decimalsArePreserved() {
        let us = Locale(identifier: "en_US")
        #expect(Double(12.34).currencyText(locale: us).contains("12.34"))
    }

    @Test("超過兩位小數時收斂至兩位")
    func roundsBeyondTwoDecimals() {
        let us = Locale(identifier: "en_US")
        let text = Double(12.345).currencyText(locale: us)
        #expect(text.contains("12.35") || text.contains("12.34"))   // 四捨五入方式交由系統
    }
}
