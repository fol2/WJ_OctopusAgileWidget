//
//  WJ_OctopusAgileWidgetApp.swift
//  WJ_OctopusAgileWidget
//
//  Created by James To on 08/09/2024.
//

import SwiftUI

/// 主應用程序結構
@main
struct WJ_OctopusAgileWidgetApp: App {
    /// 應用程序的主視圖模型
    @StateObject private var viewModel = ContentViewModel()

    /// 定義應用程序的主要場景
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    // 強制豎屏模式
                    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                    viewModel.initializeData()
                }
        }
    }
}