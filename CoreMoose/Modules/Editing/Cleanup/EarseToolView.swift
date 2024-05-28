//
//  EarseToolView.swift
//  CoreMoose
//
//  Created by m x on 2024/1/4.
//

import SwiftUI
import Vision

struct EarseToolView: View {
    @EnvironmentObject var state: EditState
    @State private var hasFeedbackOccurred = false
    var editViewModel: EditViewModel
    
    var body: some View {
        VStack {
            sliderView
                .padding(.horizontal, 50)
            toolButtons
                .font(.title2)
                .padding(.horizontal, 50)
                .padding(.bottom, 20)
        }
    }
    
    private var sliderView: some View {
        Slider(value: $state.brushSize, in: 1...140) { editing in
            state.isSliderActive = editing
        }
        .disabled(state.mode == .move)
        
    }
    
    private var toolButtons: some View {
        HStack {
            resetButton
            Spacer()
            undoButton
            Spacer()
            redoButton
            Spacer()
            textReconize
            Spacer()
            eyeButton
            Spacer()
            saveButton
            
        }
    }
    
    // Extracted button views and their logic
    
    private var resetButton: some View {
        Button {
            impactFeedback()
            state.scrollViewScale = 1.0
            if !state.undoImageData.isEmpty {
                state.imageData = state.undoImageData[0]
            }
            state.undoImageData.removeAll()
            if !state.redoImageData.isEmpty {
                state.redoImageData.removeAll()
            }
        } label: {
            Image(systemName: "gobackward")
        }
        .disabled(state.undoImageData.isEmpty && state.redoImageData.isEmpty)
    }
    
    private var undoButton: some View {
        Button {
            guard let data = state.imageData else { return }
            impactFeedback()
            state.redoImageData.append(data)
            state.imageData = state.undoImageData.removeLast()
        } label: {
            Image(systemName: "arrow.uturn.backward")
        }
        .disabled(state.undoImageData.isEmpty)
    }
    
    private var redoButton: some View {
        Button {
            guard let data = state.imageData else { return }
            impactFeedback()
            state.undoImageData.append(data)
            state.imageData = state.redoImageData.removeLast()
        } label: {
            Image(systemName: "arrow.uturn.forward")
        }
        .disabled(state.redoImageData.isEmpty)
    }
    
    private var eyeButton: some View {
        Button {} label: {
            Image(systemName: state.showingInitialImage ? "eye" : "eye.slash")
        }
        .disabled(state.undoImageData.isEmpty)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged({ _ in
                    if !hasFeedbackOccurred {
                        impactFeedback()
                        hasFeedbackOccurred = true
                        state.showingInitialImage = true
                    }
                })
                .onEnded({ _ in
                    state.showingInitialImage = false
                    hasFeedbackOccurred = false
                })
        )
    }
    
    private var saveButton: some View {
        Button {
            impactFeedback()
            state.showingSavedImage.toggle()
            state.saveImageToPhotos()
        } label: {
            Image(systemName: "square.and.arrow.down")
                .scaleEffect(state.showingSavedImage ? 1.5 : 1)
        }
        .disabled(state.undoImageData.isEmpty)
    }
    
    private var textReconize: some View {
        Button {
            impactFeedback()
            state.showRecongizedTextRect.toggle()
            Task {
                state.imageIsBeingProcessed = true
                state.recognizedRectangles =  editViewModel.analyzeImage(state: state)
                state.imageIsBeingProcessed = false
            }
        } label: {
            Image(systemName: state.showRecongizedTextRect ? "doc.text.image": "text.viewfinder")
        }
        .disabled(state.recognizedRectangles.isEmpty)
    }
}
