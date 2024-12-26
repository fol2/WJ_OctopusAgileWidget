import SwiftUI

struct HighestRateCard: View {
    let highestRate: AgileRate?
    @AppStorage("usePence") private var usePence = false

    var body: some View {
        Group {
            if let highestRate = highestRate {
                VStack(alignment: .leading, spacing: 8) {
                    Text(FormatterHelper.formatPrice(highestRate.valueIncVat, usePence: usePence))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("每千瓦時")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(FormatterHelper.formatDate(highestRate.validFrom)) \(FormatterHelper.formatTime(highestRate.validFrom)) - \(FormatterHelper.formatTime(highestRate.validTo))")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            } else {
                Text("無可用數據")
                    .foregroundColor(.primary)
            }
        }
    }
}
