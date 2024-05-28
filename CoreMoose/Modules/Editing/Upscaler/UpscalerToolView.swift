//
//  UpscalerToolView.swift
//  CoreMoose
//
//  Created by m x on 2024/1/4.
//

import SwiftUI

struct UpscalerToolView: View {
    @EnvironmentObject var state: EditState
    
    var body: some View {
        HStack {
            resetButton
            Spacer()
            toggleInitialImageButton
            Spacer()
            saveImageButton
            Spacer()
            upscaleButton
        }
        .font(.title2)
        .padding(.horizontal, 50)
        .padding(.bottom, 20)
    }

    private var resetButton: some View {
        Button {
            impactFeedback()
            resetState()
        } label: {
            Image(systemName: "gobackward")
        }
        .disabled(state.undoImageData.isEmpty && state.redoImageData.isEmpty)
    }

    private var toggleInitialImageButton: some View {
        Button {
            impactFeedback()
            state.showingInitialImage.toggle()
        } label: {
            Image(systemName: state.showingInitialImage ? "square.filled.and.line.vertical.and.square" : "square.and.line.vertical.and.square.filled")
        }
        .disabled(state.undoImageData.isEmpty)
    }

    private var saveImageButton: some View {
        Button {
            impactFeedback()
            state.saveImageToPhotos()
        } label: {
            Image(systemName: "square.and.arrow.down")
                .scaleEffect(state.showingSavedImage ? 1.5 : 1)
        }
        .disabled(state.undoImageData.isEmpty)
    }

    private var upscaleButton: some View {
        Button {
            impactFeedback()
            performUpscaling()
        } label: {
            Image(systemName: "arrowtriangle.right.circle")
        }
        .disabled(state.imageIsBeingProcessed || !state.undoImageData.isEmpty)
    }

    private func resetState() {
        state.scrollViewScale = 1.0
        if !state.undoImageData.isEmpty {
            state.imageData = state.undoImageData[0]
        }
        state.undoImageData.removeAll()
        if !state.redoImageData.isEmpty {
            state.redoImageData.removeAll()
        }
    }

    private func performUpscaling() {
        let upscalerModel = EditViewModel()
        Task {
            state.modelType = .Upscaler
            await upscalerModel.submitForInpainting(state: state)
        }
    }
}
