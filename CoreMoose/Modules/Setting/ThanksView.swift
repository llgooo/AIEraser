//
//  ThanksView.swift
//  CoreMoose
//
//  Created by m x on 2023/12/28.
//

import SwiftUI

struct ThanksView: View {
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("This application makes use of the following pretrained models:")
                    .foregroundColor(.secondary)
                Divider()
                HStack {
                    Link("LaMa", destination: URL(string: "https://github.com/advimman/lama")!)
                    Text("|")
                    Link( "MiGAN", destination: URL(string: "https://github.com/Picsart-AI-Research/MI-GAN")!)
                    Text("|")
                    Link( "Real-ESRGAN", destination: URL(string: "https://github.com/xinntao/Real-ESRGAN")!)
                }
                .padding(.top, 2)
                .foregroundColor(.primary)
            }
            .padding(.bottom, 20)
            VStack(alignment: .leading) {
                Text("Special thanks for the visuals: Photo by Taylor on Unsplash.")
                    .foregroundColor(.secondary)
                Divider()
                HStack {
                    Link("Taylor", destination: URL(string: "https://unsplash.com/@xoutcastx?utm_source=coremoose&utm_medium=referral")!)
                    Text("|")
                    Link("Unsplash", destination: URL(string: "https://unsplash.com/?utm_source=coremoose&utm_medium=referral")!)
                }
                .padding(.top, 2)
                .foregroundColor(.primary)
            }
        }
        .font(.caption)
        .multilineTextAlignment(.leading)
        .padding()
        .navigationTitle("Thanks")
        Spacer()
    }
}

#Preview {
    ThanksView()
}
