//
//  SettingModel.swift
//  CoreMoose
//
//  Created by m x on 2023/12/25.
//

import RevenueCat
import SwiftUI

class SettingViewModel: ObservableObject {
    @Published var rateLink = "https://apps.apple.com/app/id\(Constants.appId)?action=write-review"
    @Published var shareLink = "https://apps.apple.com/app/id\(Constants.appId)"
    
    @Published var isShareSheetShowing: Bool = false
    @Published var showingFeedbackView: Bool = false
    @Published var isPurchasing: Bool = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var error: NSError?
    
    @Published var offerings: Offerings? = nil
    @Published var customerInfo: CustomerInfo? {
        didSet {
            isPro = customerInfo?.entitlements[Constants.entitlementID]?.isActive == true
        }
    }
    
    @AppStorage("isPro") var isPro: Bool = false
    @AppStorage("hapticFeedbackOn") var hapticFeedbackOn: Bool = true
    @AppStorage("themeType") var themeType: ThemeType = .auto
    @AppStorage("selectedModelType") var selectedModelType: ModelType = UserDefaults.standard.currentModelType
    @AppStorage("showWatermark") var showWatermark: Bool = true
    
    var deviceInfo: String {
        UIDevice.current.systemName + " " + UIDevice.current.systemVersion
    }
    
    var appBuild: String {
        (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ??  "Unknown"
    }
    
    var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknow"
    }
    
    var appInfo: String {
        "\(Constants.appName) v\(appVersion)(\(appBuild))"
    }
    
    func purchaseProVersion() {
        Task { @MainActor in
            do {
                self.isPurchasing = true
                defer {
                    self.isPurchasing = false
                }
                if let pkg = offerings?.current?.availablePackages.first {
                    let result = try await Purchases.shared.purchase(package: pkg)
                    self.customerInfo = result.customerInfo
                }
            } catch {
                self.error = error as NSError
            }
        }
    }
    
    func restorePurchases() {
        Task { @MainActor in
            do {
                self.isPurchasing = true
                defer {
                    self.isPurchasing = false
                }
                self.customerInfo = try await Purchases.shared.restorePurchases()
                if !self.isPro {
                    self.alertMessage = "You don't have a Pro version. Would you like to purchase it now?"
                    self.showAlert = true
                }
            } catch {
                self.error = error as NSError
            }
        }
    }
    
}
