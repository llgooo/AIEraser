//
//  CoreMooseApp.swift
//  CoreMoose
//
//  Created by m x on 2023/12/4.
//

import SwiftUI
import RevenueCat

@main
struct CoreEraserApp: App {
    @StateObject var settingViewModel = SettingViewModel()
    @StateObject var navigationStore = NavigationStore()
    
    init() {
        UserDefaults.standard.register(defaults: ["hapticFeedbackOn": true, "themeType": "auto"])
        Purchases.logLevel = .info
        Purchases.configure(withAPIKey: Constants.apiKey)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(navigationStore)
                .environmentObject(settingViewModel)
                .preferredColorScheme(getColorScheme())
                .accentColor(.primary)
                .task {
                    do {
                        if UserDefaults.standard.isPro {
                            print("already purchased")
                            return
                        }
                        settingViewModel.customerInfo = try await Purchases.shared.customerInfo()
                        if !settingViewModel.isPro {
                            settingViewModel.offerings = try await Purchases.shared.offerings()
                        }
                    } catch {
                        print("Error fetching offerings: \(error)")
                    }
                }
        }
        #if os(macOS)
        .defaultSize(width: 768, height: 1224)
        #endif
        
    }
    
    private func getColorScheme() -> ColorScheme? {
        switch settingViewModel.themeType {
            case .auto:
                return nil
            case .light:
                return .light
            case .dark:
                return .dark
        }
    }
}
