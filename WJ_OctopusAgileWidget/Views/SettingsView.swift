import SwiftUI

/// 設置視圖，用於管理應用程序設置
struct SettingsView: View {
    /// 內容視圖模型
    @EnvironmentObject private var viewModel: ContentViewModel
    /// API密鑰
    @AppStorage("apiKey") private var apiKey = ""
    /// 臨時API密鑰，用於編輯
    @State private var tempApiKey = ""
    /// 是否正在編輯API密鑰
    @State private var isEditing = false
    /// 文本字段焦點狀態
    @FocusState private var isFocused: Bool
    /// 設置更新後的回調
    var onSettingsUpdated: () -> Void
    /// 賬戶號碼
    @AppStorage("accountNumber") private var accountNumber = ""
    @State private var tempAccountNumber = ""
    @State private var isEditingAccountNumber = false
    @State private var showingResetAlert = false
    @State private var isResetting = false

    /// 構建視圖的主體
    var body: some View {
        Form {
            Section(header: Text("API設置")) {
                if isEditing {
                    TextField("API密鑰", text: $tempApiKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isFocused)
                } else {
                    HStack {
                        Text("API密鑰")
                        Spacer()
                        Text(apiKey.isEmpty ? "未設置" : "已設置")
                            .foregroundColor(.secondary)
                    }
                    .onTapGesture {
                        tempApiKey = apiKey
                        isEditing = true
                        isFocused = true
                    }
                }
                
                if isEditingAccountNumber {
                    TextField("賬戶號碼", text: $tempAccountNumber)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isFocused)
                } else {
                    HStack {
                        Text("賬戶號碼")
                        Spacer()
                        Text(accountNumber.isEmpty ? "未設置" : "已設置")
                            .foregroundColor(.secondary)
                    }
                    .onTapGesture {
                        tempAccountNumber = accountNumber
                        isEditingAccountNumber = true
                        isFocused = true
                    }
                }
            }

            Section(header: Text("顯示設置")) {
                Toggle("以便士（pence）顯示價格", isOn: $viewModel.usePence)
                    .onChange(of: viewModel.usePence) { oldValue, newValue in
                        onSettingsUpdated()
                    }
                Stepper(value: $viewModel.hourDuration, in: 0.5...24, step: 0.5) {
                    Text("時間長度: \(FormatterHelper.formatHourDuration(viewModel.hourDuration))")
                }
                .onChange(of: viewModel.hourDuration) { oldValue, newValue in
                    onSettingsUpdated()
                }
            }

            Section(header: Text("儀表板設置（拖動以排序, 向左滑動以禁用）")) {
                ForEach(viewModel.dashboardOrder, id: \.self) { key in
                    dashboardRow(for: key)
                }
                .onMove { source, destination in
                    viewModel.moveDashboardItem(from: source, to: destination)
                    onSettingsUpdated()
                }
            }

            Section {
                Button(action: {
                    showingResetAlert = true
                }) {
                    Text("重置所有數據")
                        .foregroundColor(.red)
                }
                .disabled(isResetting)
            }
        }
        .alert(isPresented: $showingResetAlert) {
            Alert(
                title: Text("確認重置"),
                message: Text("這將刪除所有存儲的數據並重新加載。確定要繼續嗎？"),
                primaryButton: .destructive(Text("重置")) {
                    resetData()
                },
                secondaryButton: .cancel()
            )
        }
        .navigationTitle("設置")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing || isEditingAccountNumber {
                    Button("保存") {
                        if isEditing {
                            apiKey = tempApiKey
                            isEditing = false
                        }
                        if isEditingAccountNumber {
                            accountNumber = tempAccountNumber
                            isEditingAccountNumber = false
                        }
                        isFocused = false
                        onSettingsUpdated()
                    }
                }
            }
        }
        .onAppear(perform: viewModel.loadSettings)
        .onDisappear(perform: viewModel.saveSettings)
    }

    /// 創建儀表板行視圖
    private func dashboardRow(for key: String) -> some View {
        let isEnabled = viewModel.dashboardSettings[key, default: true]

        return HStack {
            Image(systemName: "line.horizontal.3")
                .foregroundColor(.gray)
            Text(dashboardTitle(for: key))
            Spacer()
            if !isEnabled {
                Text("已禁用")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
        .background(Color.clear)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(isEnabled ? "禁用" : "啟用") {
                withAnimation {
                    viewModel.toggleDashboardItem(key: key)
                }
            }
            .tint(isEnabled ? .red : .green)
        }
    }

    /// 獲取儀表項目的標題
    private func dashboardTitle(for key: String) -> String {
        return viewModel.dashboardItems.first(where: { $0.id == key })?.title ?? key
    }

    private func resetData() {
        isResetting = true
        CoreDataService.shared.resetAllData { success in
            if success {
                viewModel.fetchAgileRates()
            }
            isResetting = false
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(onSettingsUpdated: {})
            .environmentObject(ContentViewModel())
    }
}
