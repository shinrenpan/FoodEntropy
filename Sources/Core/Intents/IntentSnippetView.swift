import SwiftUI

// 動作完成後嵌在 Siri 對話裡的小卡（見 app-intents）。
//
// 不重用 `FoodRowView`：那是清單列，帶滑動操作的觸控區與列高假設，
// 而且由 widget target 一併編譯。這裡只要「動作 + 食材 + 一行結果」三件事。
struct IntentSnippetView: View {
    let outcome: FoodItemActionOutcome
    let name: String
    let expiryDate: Date

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: outcome.symbolName)
                .font(.title2)
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.headline)
                    .lineLimit(1)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
    }

    private var tint: Color {
        switch outcome {
        case .added, .extended: .accentColor
        case .consumed: .green
        case .wasted: .red
        }
    }

    /// 已離開清單的食材不顯示剩餘天數（見 `FoodItemActionOutcome.leavesList`），
    /// 改為只說結果；仍在清單的則顯示到期日，讓使用者確認改對了。
    private var detail: String {
        if outcome.leavesList {
            String(localized: "No longer in your list")
        } else {
            String(localized: "Expires \(expiryDate.formatted(date: .abbreviated, time: .omitted))")
        }
    }
}

#Preview("Consumed") {
    IntentSnippetView(outcome: .consumed, name: "Milk", expiryDate: .now)
}

#Preview("Extended") {
    IntentSnippetView(outcome: .extended, name: "Yogurt", expiryDate: .now.addingTimeInterval(86_400 * 7))
}
