//
//  SettingView.swift
//  CoreMoose
//
//  Created by m x on 2023/12/15.
//

import SwiftUI
import RevenueCat

struct SettingView: View {
    @EnvironmentObject var viewModel: SettingViewModel
    
    var package: Package? {
        viewModel.offerings?.current?.availablePackages.first
    }
    
    var body: some View {
        List {
            proSection
            appSection
            aboutSection
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text("Restore Purchases"),
                message: Text(viewModel.alertMessage),
                primaryButton: .default(Text("Purchase")) {
                    viewModel.purchaseProVersion()
                },
                secondaryButton: .cancel()
            )
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var proSection: some View {
        Section(header: Text("Pro"), footer: Text("Pro version: watermark-free image export").font(.footnote)) {
            Button {
                viewModel.purchaseProVersion()
            } label: {
                HStack {
                    if viewModel.isPro {
                        Group {
                            Image(systemName: "crown")
                                .frame(width: 30)
                            Text("You're Pro")
                        }
                        .foregroundColor(.purple)
                        
                    } else {
                        Image(systemName: "crown")
                            .frame(width: 30)
                        Text("Upgrading to Pro")
                        Spacer()
                        if viewModel.isPurchasing || self.package == nil {
                            ProgressView()
                        } else {
                            Text(self.package == nil ? "" : self.package?.localizedPriceString ?? "")
                        }
                    }
                }
            }
            .disabled(viewModel.isPro || self.package == nil || viewModel.isPurchasing)
            
            Button {
                viewModel.restorePurchases()
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .frame(width: 30)
                    Text("Restore Purchases")
                }
            }
            .disabled(viewModel.isPro || self.package == nil || viewModel.isPurchasing)
        }
        
    }
    
    private var appSection: some View {
        Section(header: Text("APP")) {
            Picker("Earser Model", selection: $viewModel.selectedModelType) {
                ForEach(ModelType.allCases, id: \.self) { modelType in
                    if modelType != .Upscaler {
                        Text(modelType.rawValue).tag(modelType.rawValue)
                    }
                }
            }
            Picker("Color Scheme", selection: $viewModel.themeType) {
                ForEach(ThemeType.allCases, id: \.self) { themeType in
                    Text(themeType.rawValue.capitalized).tag(themeType.rawValue)
                }
            }
            Toggle("Haptic Feedback", isOn: $viewModel.hapticFeedbackOn)
        }
    }
    
    private var aboutSection: some View {
        Section(header: Text("ABOUT"), footer: Text(viewModel.appInfo).font(.footnote)) {
            Button{
                viewModel.isShareSheetShowing = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 30)
                    Text("Share App")
                }
            }
            .sheet(isPresented: $viewModel.isShareSheetShowing) {
                ShareSheet(items: [viewModel.shareLink])
            }
            
            Button {
                rateApp(rateLink: viewModel.rateLink)
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                        .frame(width: 30)
                    Text("Rate App")
                }
            }
            
            Button {
                openEmailApp(toEmail: "gxm.web@gmail.com" ,
                             subject: "\(Constants.appName)-\(viewModel.deviceInfo)",
                             body: "")
            } label: {
                HStack {
                    Image(systemName: "envelope")
                        .frame(width: 30)
                    Text("Send Feedback")
                }
            }
            
            HStack {
                NavigationLink(destination: ThanksView()) {
                    Image(systemName: "gift")
                        .frame(width: 30)
                    Text("Thanks")
                }
            }
            
            HStack {
                NavigationLink(destination: PrivacyPolicyView()) {
                    Image(systemName: "lock.shield")
                        .frame(width: 30)
                    Text("Privacy Policy")
                }
            }
        }
        
    }
}

extension NSError: LocalizedError {
    public var errorDescription: String? {
        return self.localizedDescription
    }
    
}

#Preview {
    SettingView()
        .environmentObject(SettingViewModel())
        .tint(.primary)
}
