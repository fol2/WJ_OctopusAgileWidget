import SwiftUI

struct UpcomingRateCard: View {
    let upcomingRate: AgileRate?
    @AppStorage("usePence") private var usePence = false

    var body: some View {
        Group {
            if let upcomingRate = upcomingRate {
                VStack(alignment: .leading, spacing: 8) {
                    Text(FormatterHelper.formatPrice(upcomingRate.valueIncVat, usePence: usePence))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("每千瓦時")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(FormatterHelper.formatTime(upcomingRate.validFrom)) - \(FormatterHelper.formatTime(upcomingRate.validTo))")
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
