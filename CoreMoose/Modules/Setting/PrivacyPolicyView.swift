//
//  PrivacyPolicyView.swift
//  CoreMoose
//
//  Created by m x on 2023/12/28.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Privacy Policy")
                    .font(.title)
                    .padding(.bottom, 5)

                Text("Last updated: 01/01/2024")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)

                Group {
                    Text("This privacy policy applies to the mobile application Core Eraser. The Application is designed as a user-friendly iOS app that utilizes advanced machine learning technology to remove objects from images. All processing is performed on the device, ensuring quick and secure editing without the need to upload your photos to external servers. This allows users to easily modify their images while maintaining their privacy and control over their data.")
                    Text("\nData Storage and Handling")
                        .fontWeight(.bold)
                    Text("- The Application stores all data locally on your device.")
                    Text("- No personal or usage data is collected, stored, or shared by the Application.")
                    
                    Text("\nUser Information")
                        .fontWeight(.bold)
                    Text("- The Application does not require or collect any personal information from its users.")
                    
                    Text("\nData Sharing")
                        .fontWeight(.bold)
                    Text("- As the Application does not collect any data, there is no sharing of data with third parties.")
                    
                    Text("\nChildren's Privacy")
                        .fontWeight(.bold)
                    Text("- The Application does not collect any information from its users, including children under the age of 13.")
                    
                    Text("\nPolicy Changes")
                        .fontWeight(.bold)
                    Text("- Any changes to this privacy policy will be posted in the Application and, if applicable, notified to you.")
                    
                    Text("\nYour Consent")
                        .fontWeight(.bold)
                    Text("- By using the Application, you agree to the terms of this Privacy Policy.")
                }
                .padding(.bottom, 10)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

#Preview {
    PrivacyPolicyView()
}
