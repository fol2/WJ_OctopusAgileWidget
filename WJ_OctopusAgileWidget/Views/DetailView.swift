import SwiftUI

/// 詳細視圖，顯示Agile費率的詳細信息
struct DetailView: View {
    /// 內容視圖模型
    @EnvironmentObject private var viewModel: ContentViewModel
    /// 緩存的分組費率數據
    @State private var groupedRatesCache: [(Date, [AgileRate])] = []
    /// 滾動視圖代理
    @State private var scrollProxy: ScrollViewProxy?
    /// 視圖是否已加載
    @State private var isViewLoaded = false
    /// 數據是否已加載
    @State private var hasLoadedData = false
    /// 是否應該滾動到當前費率
    @State private var shouldScrollToCurrentRate = false

    /// 定時器，用於更新當前時間
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    /// 構建視圖的主體
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("正在加載數據...")
            } else if groupedRatesCache.isEmpty {
                VStack {
                    Text("沒有可用的費率數據")
                    Text("agileRates 數量: \(viewModel.agileRates.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                ScrollViewReader { proxy in
                    List {
                        ForEach(groupedRatesCache, id: \.0) { (date, rates) in
                            Section(header: Text(formatDate(date))) {
                                ForEach(rates) { rate in
                                    HStack {
                                        Text("\(formatTime(rate.validFrom)) - \(formatTime(rate.validTo))")
                                        Spacer()
                                        Text(FormatterHelper.formatPrice(rate.valueIncVat, usePence: viewModel.usePence) + "/kWh")
                                            .font(.subheadline)
                                    }
                                    .id(rate.id)
                                    .listRowBackground(isCurrentRate(rate) ? Color.yellow.opacity(0.3) : Color.clear)
                                }
                            }
                        }
                    }
                    .onAppear {
                        scrollProxy = proxy
                        isViewLoaded = true
                        if shouldScrollToCurrentRate {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                scrollToCurrentRate()
                                shouldScrollToCurrentRate = false
                            }
                        }
                    }
                }
                .refreshable {
                    await viewModel.refreshData()
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .navigationTitle("Octopus Agile 費率詳情")
        .onReceive(timer) { _ in
            viewModel.currentDate = Date()
            if isViewLoaded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    scrollToCurrentRate()
                }
            }
        }
        .onAppear {
            if !hasLoadedData {
                loadData()
            } else {
                shouldScrollToCurrentRate = true
            }
        }
    }

    /// 加載Agile費率數據
    private func loadData() {
        // viewModel.fetchAgileRates()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.updateGroupedRates()
            self.hasLoadedData = true
            self.shouldScrollToCurrentRate = true
        }
    }

    /// 更新緩存的分組費率數據
    private func updateGroupedRates() {
        guard !viewModel.agileRates.isEmpty else {
            groupedRatesCache = []
            print("No rates available")
            return
        }
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: viewModel.agileRates) { rate in
            calendar.startOfDay(for: rate.validFrom)
        }
        groupedRatesCache = grouped.sorted { $0.key < $1.key }
        print("Updated grouped rates: \(groupedRatesCache.count) days, total rates: \(viewModel.agileRates.count)")
    }

    /// 格式化日期
    private func formatDate(_ date: Date) -> String {
        return FormatterHelper.formatDate(date)
    }

    /// 格式化時間
    private func formatTime(_ date: Date) -> String {
        return FormatterHelper.formatTime(date)
    }

    /// 檢查給定費率是否為當前費率
    private func isCurrentRate(_ rate: AgileRate) -> Bool {
        return rate.validFrom <= viewModel.currentDate && viewModel.currentDate < rate.validTo
    }

    /// 滾動到當前費率
    private func scrollToCurrentRate() {
        guard isViewLoaded, !viewModel.agileRates.isEmpty else { return }
        if let currentRate = viewModel.agileRates.first(where: isCurrentRate) {
            DispatchQueue.main.async {
                withAnimation {
                    self.scrollProxy?.scrollTo(currentRate.id, anchor: .center)
                }
            }
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView()
            .environmentObject(ContentViewModel())
    }
}
