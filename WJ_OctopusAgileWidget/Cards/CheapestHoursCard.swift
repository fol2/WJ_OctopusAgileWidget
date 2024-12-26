import SwiftUI

struct CheapestHoursCard: View {
    let agileRates: [AgileRate]
    let hourDuration: Double
    @AppStorage("usePence") private var usePence = false

    private func getCheapestHoursPerZone() -> [(zoneStart: Date, zoneEnd: Date, cheapestHours: (start: Date, end: Date, rate: Double))] {
        let mergedZones = getMergedAverageRateZones()
        return DateHelper.getCheapestHoursPerZone(mergedZones: mergedZones, agileRates: agileRates, hourDuration: hourDuration)
    }

    private func getMergedAverageRateZones() -> [(Date, Date, Double)] {
        let lowestAverageRates = getLowestAverageRates()
        let topAverageRateZones = DateHelper.getTopAverageRateZones(lowestAverageRates: lowestAverageRates)
        return DateHelper.getMergedAverageRateZones(topAverageRateZones: topAverageRateZones)
    }

    private func getLowestAverageRates() -> [(Date, Date, Double)]? {
        return DateHelper.getLowestAverageRates(agileRates: agileRates, hourDuration: hourDuration)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            let zones = getCheapestHoursPerZone()
            if zones.isEmpty {
                Text("無可用數據")
                    .foregroundColor(.primary)
            } else {
                ForEach(Array(zones.enumerated()), id: \.element.zoneStart) { index, zone in
                    VStack(alignment: .leading, spacing: 5) {
                        Text("最佳\(FormatterHelper.formatHourDuration(hourDuration)): \(FormatterHelper.formatTime(zone.cheapestHours.start)) - \(FormatterHelper.formatTime(zone.cheapestHours.end))")
                            .font(.headline)
                        HStack {
                            Text("\(FormatterHelper.formatPrice(zone.cheapestHours.rate, usePence: usePence))/kWh")
                                .font(.subheadline)
                                .foregroundColor(.green)
                            Spacer()
                            Text("區間: \(FormatterHelper.formatDate(zone.zoneStart)) \(FormatterHelper.formatTime(zone.zoneStart)) - \(FormatterHelper.formatTime(zone.zoneEnd))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                    if index < zones.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
}
