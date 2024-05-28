//
//  UpscaleView.swift
//  CoreMoose
//
//  Created by m x on 2023/12/26.
//

import SwiftUI
import Photos

struct UpscalerView: View {
    @EnvironmentObject var navigationStore: NavigationStore
    @StateObject var state: EditState
    
    init(photoData: Data) {
        _state = StateObject(wrappedValue: EditState(photoData: photoData))
    }
    
    var currentPhoto: ShareableImage {
        guard let data = state.imageData, let image = UIImage(data: data) else {
            return ShareableImage(image: Image(""), caption: "")
        }
        return ShareableImage(image: Image(uiImage: image), caption: "CoreMoose Upscaler")
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            
            Image(uiImage: UIImage(data: state.imageData!)!)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(state.scrollViewScale)
                .overlay(opacityLoadingOverlay())
                .overlay(loadingSpinnerView())
                .overlay(showInitImageOverlay())
                .overlay(showSavedImageOverlay())
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            state.scrollViewScale = max(value, 1.0)
                        }
                )
            
            Spacer()
            
            UpscalerToolView()
                .environmentObject(state)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("AI Upscaler")
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button {
                    navigationStore.dismissView()
                } label: {
                    Image(systemName: "xmark")
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ShareLink(
                    item: currentPhoto,
                    preview: SharePreview("Photo selected", image: currentPhoto.image)
                )
            }
        }
    }
    
    @ViewBuilder
    func showInitImageOverlay() -> some View {
        if state.showingInitialImage {
            if !state.undoImageData.isEmpty {
                Image(uiImage: UIImage(data: state.undoImageData[0])!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(state.scrollViewScale)
            }
        }
    }
    
    @ViewBuilder
    func showSavedImageOverlay() -> some View {
        if state.showingSavedImage {
            ZStack {
                Color.black.opacity(0.2)
                Image(systemName: "photo.badge.checkmark.fill")
                    .foregroundColor(.primary)
                    .font(.title)
            }
        }
    }
    
    @ViewBuilder
    func loadingSpinnerView() -> some View {
        if state.imageIsBeingProcessed {
            ProgressView()
                .tint(.purple)
        }
    }
    
    @ViewBuilder
    func opacityLoadingOverlay() -> some View {
        if state.imageIsBeingProcessed {
            Color.black.opacity(0.2)
        }
    }
}



#Preview {
    NavigationStack {
        UpscalerView(photoData: UIImage(named: "p1")!.pngData()!)
               .environmentObject(NavigationStore())
               .tint(.primary)
    }
}

