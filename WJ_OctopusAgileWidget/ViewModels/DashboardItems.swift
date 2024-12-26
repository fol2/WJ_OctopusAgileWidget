import SwiftUI

struct DashboardItem: Identifiable {
    let id: String
    let title: String
    var content: () -> AnyView
    let color: Color
}

extension ContentViewModel {
    var dashboardItems: [DashboardItem] {
        [
            DashboardItem(
                id: "rateChart",
                title: "費率趨勢",
                content: { AnyView(RateChartCard(rates: self.getRecentAndUpcomingRates(), currentDate: self.currentDate, hourDuration: self.hourDuration)) },
                color: .blue
            ),
            DashboardItem(
                id: "cheapestHours",
                title: "每個區間最便宜的\(FormatterHelper.formatHourDuration(hourDuration))",
                content: { AnyView(CheapestHoursCard(agileRates: self.agileRates, hourDuration: self.hourDuration)) },
                color: .green
            ),
            DashboardItem(
                id: "currentRate",
                title: "當前費率",
                content: { AnyView(CurrentRateCard(currentRate: self.getCurrentRate())) },
                color: .blue
            ),
            DashboardItem(
                id: "upcomingRate",
                title: "即將到來的費率",
                content: { AnyView(UpcomingRateCard(upcomingRate: self.getUpcomingRate())) },
                color: .green
            ),
            DashboardItem(
                id: "lowestRate",
                title: "最低費率",
                content: { AnyView(LowestRateCard(lowestRate: self.getFutureLowestRate())) },
                color: .purple
            ),
            DashboardItem(
                id: "highestRate",
                title: "最高費率",
                content: { AnyView(HighestRateCard(highestRate: self.getFutureHighestRate())) },
                color: .orange
            ),
            DashboardItem(
                id: "lowestAverageRate",
                title: "未來\(FormatterHelper.formatHourDuration(hourDuration))平均最低費率",
                content: { AnyView(LowestAverageRateCard(agileRates: self.agileRates, hourDuration: self.hourDuration)) },
                color: .teal
            ),
        ]
    }
}
