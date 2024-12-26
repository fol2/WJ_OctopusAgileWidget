import SwiftUI

struct CurrentRateCard: View {
    let currentRate: AgileRate?
    @AppStorage("usePence") private var usePence = false

    var body: some View {
        Group {
            if let currentRate = currentRate {
                VStack(alignment: .leading, spacing: 8) {
                    Text(FormatterHelper.formatPrice(currentRate.valueIncVat, usePence: usePence))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("每千瓦時")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(FormatterHelper.formatTime(currentRate.validFrom)) - \(FormatterHelper.formatTime(currentRate.validTo))")
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
