import SwiftUI

struct FormatterHelper {
    static func formatPrice(_ priceInPence: Double, usePence: Bool) -> String {
        let formatter = NumberFormatter()

        if usePence {
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            let formattedNumber = formatter.string(from: NSNumber(value: priceInPence)) ?? ""
            return "\(formattedNumber)p"
        } else {
            formatter.numberStyle = .currency
            formatter.currencySymbol = "£"
            formatter.minimumFractionDigits = 4
            formatter.maximumFractionDigits = 4
            let priceInPounds = priceInPence / 100.0
            return formatter.string(from: NSNumber(value: priceInPounds)) ?? ""
        }
    }

    static func formatAxisPrice(_ priceInPounds: Double, usePence: Bool) -> String {
        let formatter = NumberFormatter()
        if usePence {
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
            let priceInPence = priceInPounds * 100.0
            let formattedNumber = formatter.string(from: NSNumber(value: priceInPence)) ?? ""
            return "\(formattedNumber)p"
        } else {
            formatter.numberStyle = .currency
            formatter.currencySymbol = "£"
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            let formattedNumber = formatter.string(from: NSNumber(value: priceInPounds)) ?? ""
            return formattedNumber
        }
    }

    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    static func formatAxisTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: date)
        
        let hour = Calendar.current.component(.hour, from: date)
        let minute = Calendar.current.component(.minute, from: date)
        
        if minute == 0 {
            if hour == 0 {
                return "午夜"
            } else if hour == 12 {
                return "中午"
            } else if hour > 12 {
                return "\(hour - 12)pm"
            } else {
                return "\(hour)am"
            }
        } else {
            return timeString
        }
    }
    
    static func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M"
        return formatter.string(from: date)
    }

    static func formatHourDuration(_ duration: Double) -> String {
        if duration.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(duration)) 小時"
        } else {
            return String(format: "%.1f 小時", duration)
        }
    }
}

struct DateHelper {
    static func getYAxisDomain(rates: [AgileRate]) -> ClosedRange<Double> {
        let rateValues = rates.map { $0.valueIncVat / 100.0 }
        let minRate = rateValues.min() ?? 0
        let maxRate = rateValues.max() ?? 0.5
        let padding = (maxRate - minRate) * 0.1
        return (minRate - padding)...(maxRate + padding)
    }

    static func getChartXDomain(agileRates: [AgileRate]) -> ClosedRange<Date> {
        let now = Date()
        let calendar = Calendar.current
        let twoHoursAgo = calendar.date(byAdding: .hour, value: -2, to: now)!

        let endOfToday = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)

        let endDate: Date
        if endOfToday.timeIntervalSince(now) < 3 * 3600 {
            endDate = calendar.date(byAdding: .day, value: 1, to: endOfToday)!
        } else {
            endDate = max(endOfToday, agileRates.last?.validTo ?? now)
        }

        return twoHoursAgo...endDate
    }

    static func getImportantTimeMarks(currentDate: Date, mergedAverageRateZones: [(Date, Date, Double)]) -> [Date] {
        var marks = Set<Date>()
        marks.insert(currentDate)

        for (start, end, _) in mergedAverageRateZones {
            marks.insert(start)
            marks.insert(end)
        }

        return Array(marks).sorted()
    }

    static func getMidnightDates(chartDomain: ClosedRange<Date>) -> [Date] {
        let calendar = Calendar.current
        var currentDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: chartDomain.lowerBound))!
        var dates: [Date] = []

        while currentDate < chartDomain.upperBound {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return dates
    }

    static func getRecentAndUpcomingRates(agileRates: [AgileRate], chartDomain: ClosedRange<Date>) -> [AgileRate] {
        return agileRates.filter { $0.validFrom >= chartDomain.lowerBound && $0.validTo <= chartDomain.upperBound }
    }

    static func getCurrentRate(agileRates: [AgileRate]) -> AgileRate? {
        let now = Date()
        return agileRates.first { $0.validFrom <= now && now < $0.validTo }
    }

    static func getUpcomingRate(agileRates: [AgileRate]) -> AgileRate? {
        let now = Date()
        return agileRates.first { $0.validFrom > now }
    }

    static func getFutureLowestRate(agileRates: [AgileRate]) -> AgileRate? {
        let now = Date()
        return agileRates.filter { $0.validFrom > now }.min(by: { $0.valueIncVat < $1.valueIncVat })
    }

    static func getFutureHighestRate(agileRates: [AgileRate]) -> AgileRate? {
        let now = Date()
        return agileRates.filter { $0.validFrom > now }.max(by: { $0.valueIncVat < $1.valueIncVat })
    }

    static func getLowestAverageRates(agileRates: [AgileRate], hourDuration: Double) -> [(Date, Date, Double)]? {
        let now = Date()
        let futureRates = agileRates.filter { $0.validFrom > now }
        let periodCount = Int(hourDuration * 2)
        guard futureRates.count >= periodCount else { return nil }

        var averageRates: [(Date, Date, Double)] = []

        for i in 0...(futureRates.count - periodCount) {
            let slice = Array(futureRates[i..<(i+periodCount)])
            let average = slice.reduce(0.0) { $0 + $1.valueIncVat } / Double(periodCount)
            let startTime = slice.first!.validFrom
            let endTime = slice.last!.validTo
            averageRates.append((startTime, endTime, average))
        }

        return averageRates.sorted { $0.2 < $1.2 }
    }

    static func getTopAverageRateZones(lowestAverageRates: [(Date, Date, Double)]?) -> [(Date, Date, Double)] {
        return Array((lowestAverageRates ?? []).prefix(10))
    }

    static func getMergedAverageRateZones(topAverageRateZones: [(Date, Date, Double)]) -> [(Date, Date, Double)] {
        let zones = topAverageRateZones.sorted(by: { $0.0 < $1.0 })
        var mergedZones: [(Date, Date, Double)] = []

        for zone in zones {
            if let index = mergedZones.firstIndex(where: {
                max($0.0, zone.0) <= min($0.1, zone.1)
            }) {
                let existingZone = mergedZones[index]
                let newStartTime = min(existingZone.0, zone.0)
                let newEndTime = max(existingZone.1, zone.1)
                let totalDuration = newEndTime.timeIntervalSince(newStartTime)

                let existingDuration = existingZone.1.timeIntervalSince(existingZone.0)
                let zoneDuration = zone.1.timeIntervalSince(zone.0)
                let existingWeight = existingZone.2 * existingDuration
                let zoneWeight = zone.2 * zoneDuration
                let weightedAverage = (existingWeight + zoneWeight) / totalDuration

                mergedZones[index] = (newStartTime, newEndTime, weightedAverage)
            } else {
                mergedZones.append(zone)
            }
        }

        var i = 0
        while i < mergedZones.count {
            var j = i + 1
            while j < mergedZones.count {
                if max(mergedZones[i].0, mergedZones[j].0) <= min(mergedZones[i].1, mergedZones[j].1) {
                    let newStartTime = min(mergedZones[i].0, mergedZones[j].0)
                    let newEndTime = max(mergedZones[i].1, mergedZones[j].1)
                    let totalDuration = newEndTime.timeIntervalSince(newStartTime)
                    let existingDuration = mergedZones[i].1.timeIntervalSince(mergedZones[i].0)
                    let zoneDuration = mergedZones[j].1.timeIntervalSince(mergedZones[j].0)
                    let existingWeight = mergedZones[i].2 * existingDuration
                    let zoneWeight = mergedZones[j].2 * zoneDuration
                    let weightedAverage = (existingWeight + zoneWeight) / totalDuration
                    mergedZones[i] = (newStartTime, newEndTime, weightedAverage)
                    mergedZones.remove(at: j)
                } else {
                    j += 1
                }
            }
            i += 1
        }

        return mergedZones.sorted(by: { $0.0 < $1.0 })
    }

    static func getCheapestHoursPerZone(mergedZones: [(Date, Date, Double)], agileRates: [AgileRate], hourDuration: Double) -> [(zoneStart: Date, zoneEnd: Date, cheapestHours: (start: Date, end: Date, rate: Double))] {
        var result: [(zoneStart: Date, zoneEnd: Date, cheapestHours: (start: Date, end: Date, rate: Double))] = []
        let periodCount = Int(hourDuration * 2)

        for (zoneStart, zoneEnd, _) in mergedZones {
            let zoneRates = agileRates.filter { $0.validFrom >= zoneStart && $0.validTo <= zoneEnd }

            if zoneRates.count >= periodCount {
                var cheapestHours: (start: Date, end: Date, rate: Double) = (start: zoneStart, end: zoneStart, rate: Double.infinity)

                for i in 0...(zoneRates.count - periodCount) {
                    let slice = Array(zoneRates[i..<(i+periodCount)])
                    let averageRate = slice.reduce(0.0) { $0 + $1.valueIncVat } / Double(periodCount)

                    if averageRate < cheapestHours.rate {
                        cheapestHours = (start: slice.first!.validFrom,
                                         end: slice.last!.validTo,
                                         rate: averageRate)
                    }
                }

                result.append((zoneStart: zoneStart, zoneEnd: zoneEnd, cheapestHours: cheapestHours))
            }
        }

        return result
    }
}