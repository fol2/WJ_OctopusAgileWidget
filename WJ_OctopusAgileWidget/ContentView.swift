//
//  ContentView.swift
//  WJ_OctopusAgileWidget
//
//  Created by James To on 08/09/2024.
//

import SwiftUI

/// 主內容視圖
struct ContentView: View {
    /// 內容視圖模型
    @EnvironmentObject private var viewModel: ContentViewModel

    /// 構建視圖的主體
    var body: some View {
        NavigationView {
            List {
                dashboardContent
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }
            .listStyle(PlainListStyle())
            .refreshable {
                await viewModel.refreshData()
            }
            .navigationTitle("Octopus Agile 儀表板")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: DetailView()) {
                        Image(systemName: "list.bullet")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView(onSettingsUpdated: {
                        viewModel.loadSettings()
                    })) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .onAppear {
            viewModel.initializeData()
        }
        .onReceive(viewModel.timer) { _ in
            viewModel.updateDashboard()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            viewModel.loadSettings()
        }
        .onChange(of: viewModel.dashboardSettingsData) { oldValue, newValue in
            viewModel.loadSettings()
        }
        .onChange(of: viewModel.dashboardOrderData) { oldValue, newValue in
            viewModel.loadSettings()
        }
    }

    /// 創建儀表板內容
    private var dashboardContent: some View {
        VStack(spacing: 20) {
            ForEach(viewModel.dashboardOrder, id: \.self) { key in
                if viewModel.dashboardSettings[key] ?? true {
                    viewModel.dashboardItems
                        .first(where: { $0.id == key })
                        .map { item in
                            DashboardCard(
                                title: item.title,
                                content: item.content(),
                                color: item.color
                            )
                        }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

/// 儀表板卡片視圖
struct DashboardCard: View {
    /// 卡片標題
    let title: String
    /// 卡片內容
    let content: AnyView
    /// 卡片顏色
    let color: Color

    /// 構建卡片視圖
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: color.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ContentViewModel())
    }
}
