import SwiftUI

struct LowestRateCard: View {
    let lowestRate: AgileRate?
    @AppStorage("usePence") private var usePence = false

    var body: some View {
        Group {
            if let lowestRate = lowestRate {
                VStack(alignment: .leading, spacing: 8) {
                    Text(FormatterHelper.formatPrice(lowestRate.valueIncVat, usePence: usePence))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("每千瓦時")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(FormatterHelper.formatDate(lowestRate.validFrom)) \(FormatterHelper.formatTime(lowestRate.validFrom)) - \(FormatterHelper.formatTime(lowestRate.validTo))")
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
