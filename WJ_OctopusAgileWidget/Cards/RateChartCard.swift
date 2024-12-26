import SwiftUI
import Charts

struct RateChartCard: View {
    let rates: [AgileRate]
    let currentDate: Date
    let hourDuration: Double
    @AppStorage("usePence") private var usePence = false

    private func getYAxisDomain() -> ClosedRange<Double> {
        return DateHelper.getYAxisDomain(rates: rates)
    }
    
    private func getChartXDomain() -> ClosedRange<Date> {
        return DateHelper.getChartXDomain(agileRates: rates)
    }
    
    private func getImportantTimeMarks() -> [Date] {
        let mergedZones = getMergedAverageRateZones()
        return DateHelper.getImportantTimeMarks(currentDate: currentDate, mergedAverageRateZones: mergedZones)
    }
    
    private func getMergedAverageRateZones() -> [(Date, Date, Double)] {
        let lowestAverageRates = getLowestAverageRates()
        let topAverageRateZones = DateHelper.getTopAverageRateZones(lowestAverageRates: lowestAverageRates)
        return DateHelper.getMergedAverageRateZones(topAverageRateZones: topAverageRateZones)
    }
    
    private func getMidnightDates() -> [Date] {
        let chartDomain = getChartXDomain()
        return DateHelper.getMidnightDates(chartDomain: chartDomain)
    }
    
    private func getCurrentRate() -> AgileRate? {
        return DateHelper.getCurrentRate(agileRates: rates)
    }
    
    private func getLowestAverageRates() -> [(Date, Date, Double)]? {
        return DateHelper.getLowestAverageRates(agileRates: rates, hourDuration: hourDuration)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            dateLabelsOverlay
                .frame(height: 20)
            Chart {
                // Plot the rates line
                ForEach(rates) { rate in
                    LineMark(
                        x: .value("Time", rate.validFrom),
                        y: .value("Rate", rate.valueIncVat / 100.0)
                    )
                    .foregroundStyle(rate.validFrom < currentDate ? Color.blue.opacity(0.5) : Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .interpolationMethod(.catmullRom)

                // Highlight merged average rate zones
                ForEach(getMergedAverageRateZones(), id: \.0) { startTime, endTime, _ in
                    RectangleMark(
                        xStart: .value("Start", startTime),
                        xEnd: .value("End", endTime),
                        yStart: .value("Min", getYAxisDomain().lowerBound),
                        yEnd: .value("Max", getYAxisDomain().upperBound)
                    )
                    .foregroundStyle(Color.green.opacity(0.3))
                }

                // Add midnight vertical lines
                ForEach(getMidnightDates(), id: \.self) { date in
                    RuleMark(x: .value("Midnight", date))
                        .foregroundStyle(Color.blue)
                        .lineStyle(StrokeStyle(lineWidth: 0.25))
                }

                // Add current time marker
                if let currentRate = getCurrentRate() {
                    RuleMark(
                        x: .value("Current Time", currentDate)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    
                    PointMark(
                        x: .value("Current Time", currentDate),
                        y: .value("Current Rate", currentRate.valueIncVat / 100.0)
                    )
                    .foregroundStyle(.red)
                    .symbolSize(40)
                }
            }
            .chartXScale(domain: getChartXDomain())
            .chartXAxis {
                AxisMarks(preset: .aligned, values: getImportantTimeMarks()) { value in
                    if let date = value.as(Date.self) {
                        let isCurrentTime = date == currentDate
                        let shouldShowLabel = !isCurrentTime || !isOverlapping(date: date, allMarks: getImportantTimeMarks())
                        
                        AxisGridLine()
                        AxisTick()
                        if shouldShowLabel {
                            AxisValueLabel {
                                Text(FormatterHelper.formatAxisTime(date))
                                    .font(.caption)
                                    .foregroundColor(isCurrentTime ? .red : .primary)
                            }
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        Text(FormatterHelper.formatAxisPrice(value.as(Double.self) ?? 0, usePence: usePence))
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
            .chartYScale(domain: getYAxisDomain())
            .frame(height: 200)
            .padding(.leading, 0)
        }
        .padding(.leading, -10)
    }
    
    private var dateLabelsOverlay: some View {
        GeometryReader { geometry in
            let dates = getUniqueDatesWithToday()
            ForEach(dates, id: \.self) { date in
                Text(FormatterHelper.formatAxisDate(date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .position(
                        x: getXPosition(for: date, in: geometry.size.width),
                        y: 10
                    )
            }
        }
    }
    
    private func getUniqueDatesWithToday() -> [Date] {
        let chartDomain = getChartXDomain()
        let calendar = Calendar.current
        var dates = Set<Date>()
        
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let currentHour = calendar.component(.hour, from: Date())
        
        dates.insert(today)
        
        // Only add tomorrow's date if current time is after 4 pm
        if currentHour >= 16 && chartDomain.upperBound >= tomorrow {
            dates.insert(tomorrow)
        }

        return Array(dates).sorted()
    }
    
    private func getXPosition(for date: Date, in width: CGFloat) -> CGFloat {
        let domain = getChartXDomain()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: domain.lowerBound)
        let currentHour = calendar.component(.hour, from: Date())
        
        let yAxisWidth: CGFloat = 45
        let chartWidth = width - yAxisWidth
        let nextMidnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: domain.lowerBound)!)
        
        if currentHour >= 0 && currentHour < 16 {
            // From 0 to 16 hours, only one date label
            if currentHour < 2 {
                // From 0 to 2 am, use calculated position
                let midnightPosition = yAxisWidth + (chartWidth * CGFloat(nextMidnight.timeIntervalSince(domain.lowerBound) / domain.upperBound.timeIntervalSince(domain.lowerBound)))
                return midnightPosition
            } else {
                // From 2 am to 4 pm, put label on the left
                return yAxisWidth
            }
        } else {
            // After 4 pm, show two date labels
            if date <= startOfDay {
                return yAxisWidth // First date on the left
            } else {
                // Second date (tomorrow) position
                let midnightPosition = yAxisWidth + (chartWidth * CGFloat(nextMidnight.timeIntervalSince(domain.lowerBound) / domain.upperBound.timeIntervalSince(domain.lowerBound)))
                return midnightPosition
            }
        }
    }
    
    private func isOverlapping(date: Date, allMarks: [Date]) -> Bool {
        let currentIndex = allMarks.firstIndex(of: date) ?? 0
        
        // Check previous and next time labels
        for offset in [-1, 1] {
            let neighborIndex = currentIndex + offset
            if neighborIndex >= 0 && neighborIndex < allMarks.count {
                let neighborDate = allMarks[neighborIndex]
                let timeDifference = abs(date.timeIntervalSince(neighborDate))
                
                // If time difference is less than 90 minutes, consider overlapping
                if timeDifference < 90 * 60 {
                    return true
                }
            }
        }
        
        return false
    }
}
