import SwiftUI

struct LowestAverageRateCard: View {
    let agileRates: [AgileRate]
    let hourDuration: Double
    @AppStorage("usePence") private var usePence = false

    private func getLowestAverageRates() -> [(Date, Date, Double)]? {
        return DateHelper.getLowestAverageRates(agileRates: agileRates, hourDuration: hourDuration)
    }

    var body: some View {
        Group {
            if let lowestAverageRates = getLowestAverageRates() {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(lowestAverageRates.prefix(10), id: \.0) { startTime, endTime, averageRate in
                        HStack {
                            Text(FormatterHelper.formatPrice(averageRate, usePence: usePence))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(FormatterHelper.formatDate(startTime))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(FormatterHelper.formatTime(startTime)) - \(FormatterHelper.formatTime(endTime))")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            } else {
                Text("無可用數據")
                    .foregroundColor(.primary)
            }
        }
    }
}
