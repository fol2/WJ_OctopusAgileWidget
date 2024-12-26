import SwiftUI

/// 內容視圖模型，管理應用程序的主要數據和邏輯
class ContentViewModel: ObservableObject {
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    /// Agile費率數據
    @Published var agileRates: [AgileRate] = []
    /// 是否正在加載數據
    @Published var isLoading = false
    /// 錯誤消息
    @Published var errorMessage: String?
    /// 是否正在刷新數據
    @Published var isRefreshing = false
    /// 當前日期
    @Published var currentDate = Date()
    /// 是否應該刷新數據
    @Published var shouldRefresh = false

    /// 儀表板設置
    @Published var dashboardSettings: [String: Bool] = [:]
    /// 儀表板順序
    @Published var dashboardOrder: [String] = []

    /// 儀表板設置數據
    @AppStorage("dashboardSettings") var dashboardSettingsData: Data = Data()
    /// 儀表板順序數據
    @AppStorage("dashboardOrder") var dashboardOrderData: Data = Data()
    /// 是否使用便士顯示價格
    @AppStorage("usePence") var usePence = false
    /// 小時持續時間
    @AppStorage("hourDuration") var hourDuration = 3.0

    /// 初始化視圖模型
    init() {
        loadSettings()
    }

    /// 加載設置
    func loadSettings() {
        if let decodedSettings = try? JSONDecoder().decode([String: Bool].self, from: dashboardSettingsData) {
            dashboardSettings = decodedSettings
        }
        if let decodedOrder = try? JSONDecoder().decode([String].self, from: dashboardOrderData) {
            dashboardOrder = decodedOrder
        }
    }

    /// 獲取Agile費率數據
    func fetchAgileRates() {
        isLoading = true
        errorMessage = nil

        OctopusAPIService.shared.fetchAgileRates { result in
            DispatchQueue.main.async {
                self.isLoading = false
                self.isRefreshing = false
                switch result {
                case .success(let rates):
                    self.agileRates = rates.sorted(by: { $0.validFrom < $1.validFrom })
                    print("Fetched \(rates.count) rates")
                    // 清理舊數據
                    CoreDataService.shared.cleanupOldRates()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("Error fetching rates: \(error.localizedDescription)")
                    // 如果網絡請求失敗，嘗試從Core Data加載數據
                    let storedRates = CoreDataService.shared.fetchAgileRates().map { entity -> AgileRate in
                        return AgileRate(validFrom: entity.validFrom ?? Date(), validTo: entity.validTo ?? Date(), valueExcVat: entity.valueExcVat, valueIncVat: entity.valueIncVat)
                    }
                    self.agileRates = storedRates.sorted(by: { $0.validFrom < $1.validFrom })
                }
            }
        }
    }

    /// 刷新數據
    func refreshData() async {
        await withCheckedContinuation { continuation in
            fetchAgileRates()
            continuation.resume()
        }
    }

    /// 更新儀表板
    func updateDashboard() {
        let now = Date()
        currentDate = now
        if Calendar.current.component(.minute, from: now) % 30 == 0 {
            fetchAgileRates()
        }
    }

    /// 獲取最近和即將到來的費率
    func getRecentAndUpcomingRates() -> [AgileRate] {
        let chartDomain = DateHelper.getChartXDomain(agileRates: agileRates)
        return DateHelper.getRecentAndUpcomingRates(agileRates: agileRates, chartDomain: chartDomain)
    }

    /// 獲取當前費率
    func getCurrentRate() -> AgileRate? {
        return DateHelper.getCurrentRate(agileRates: agileRates)
    }

    /// 獲取即將到來的費率
    func getUpcomingRate() -> AgileRate? {
        return DateHelper.getUpcomingRate(agileRates: agileRates)
    }

    /// 獲取未來最低費率
    func getFutureLowestRate() -> AgileRate? {
        return DateHelper.getFutureLowestRate(agileRates: agileRates)
    }

    /// 獲取未來最高費率
    func getFutureHighestRate() -> AgileRate? {
        return DateHelper.getFutureHighestRate(agileRates: agileRates)
    }

    /// 獲取最低平均費率
    func getLowestAverageRates() -> [(Date, Date, Double)]? {
        return DateHelper.getLowestAverageRates(agileRates: agileRates, hourDuration: hourDuration)
    }

    /// 獲取Y軸域
    func getYAxisDomain() -> ClosedRange<Double> {
        return DateHelper.getYAxisDomain(rates: getRecentAndUpcomingRates())
    }

    /// 獲取頂部平均費率區域
    func getTopAverageRateZones() -> [(Date, Date, Double)] {
        let lowestAverageRates = getLowestAverageRates()
        return DateHelper.getTopAverageRateZones(lowestAverageRates: lowestAverageRates)
    }

    /// 獲取合併的平均費率區域
    func getMergedAverageRateZones() -> [(Date, Date, Double)] {
        let topAverageRateZones = getTopAverageRateZones()
        return DateHelper.getMergedAverageRateZones(topAverageRateZones: topAverageRateZones)
    }

    /// 獲取圖表X軸域
    func getChartXDomain() -> ClosedRange<Date> {
        return DateHelper.getChartXDomain(agileRates: agileRates)
    }

    /// 獲取重要時間標記
    func getImportantTimeMarks() -> [Date] {
        let mergedZones = getMergedAverageRateZones()
        return DateHelper.getImportantTimeMarks(currentDate: currentDate, mergedAverageRateZones: mergedZones)
    }

    /// 獲取午夜日期
    func getMidnightDates() -> [Date] {
        let chartDomain = getChartXDomain()
        return DateHelper.getMidnightDates(chartDomain: chartDomain)
    }

    /// 獲取每個區域的最便宜小時
    func getCheapestHoursPerZone() -> [(zoneStart: Date, zoneEnd: Date, cheapestHours: (start: Date, end: Date, rate: Double))] {
        let mergedZones = getMergedAverageRateZones()
        return DateHelper.getCheapestHoursPerZone(mergedZones: mergedZones, agileRates: agileRates, hourDuration: hourDuration)
    }

    /// 初始化數據
    func initializeData() {
        loadSettings()
    }

    /// 刷新數據和設置
    func refreshDataAndSettings() {
        fetchAgileRates()
        loadSettings()
    }

    /// 移動儀表板項目
    func moveDashboardItem(from source: IndexSet, to destination: Int) {
        dashboardOrder.move(fromOffsets: source, toOffset: destination)
        saveSettings()
    }

    /// 切換儀表板項目
    func toggleDashboardItem(key: String) {
        dashboardSettings[key]?.toggle()
        saveSettings()
    }

    /// 保存設置
    func saveSettings() {
        if let encodedSettings = try? JSONEncoder().encode(dashboardSettings) {
            dashboardSettingsData = encodedSettings
        }
        if let encodedOrder = try? JSONEncoder().encode(dashboardOrder) {
            dashboardOrderData = encodedOrder
        }
    }
}