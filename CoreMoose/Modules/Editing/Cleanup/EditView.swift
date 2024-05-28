//
//  EditView.swift
//  CoreMoose
//
//  Created by m x on 2023/12/5.
//

import SwiftUI
import Photos

struct EditView: View {
    @EnvironmentObject var navigationStore: NavigationStore
    
    @StateObject private var editViewModel: EditViewModel = EditViewModel()
    @StateObject private var state: EditState
    
    @State private var processingTask: Task<Void, Never>? = nil
    
    init(photoData: Data) {
        _state = StateObject(wrappedValue: EditState(photoData: photoData))
    }
    
    var currentlyEditablePhoto: ShareableImage {
        guard let data = state.imageData, var image = UIImage(data: data) else {
            return ShareableImage(image: Image(""), caption: "")
        }
        if !UserDefaults.standard.isPro {
            image = addWatermarkToImage(image)
        }
        return ShareableImage(image: Image(uiImage: image), caption: "AI Eraser")
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            
            ZoomableScrollView(contentScale: $state.scrollViewScale) {
                ImageMaskingView(isModelLoaded: editViewModel.isModelLoaded)
                    .environmentObject(state)
            }
            .overlay(loadingModelSpinnerView())
            .overlay(brushSizeOverlay())
            .overlay(showSavedImageOverlay())
            .onChange(of: state.scrollViewScale) { newValue in
                state.brushSize = state.baseBrushSize / newValue
            }
            
            Spacer()
            
            editModePicker()
                .pickerStyle(.segmented)
                .onChange(of: state.selectedIndex) { newSelectedIndex in
                    let newState = getNewState(for: newSelectedIndex)
                    state.mode = newState
                    if newState == .standardMask {
                        state.isSliderActive = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            state.isSliderActive = false
                        }
                    }
                }
                .padding(.horizontal, 50)
            
            
            EarseToolView(editViewModel: editViewModel)
                .environmentObject(state)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("AI Eraser")
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button{
                    navigationStore.dismissView()
                } label: {
                    Image(systemName: "xmark")
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ShareLink(
                    item: currentlyEditablePhoto,
                    preview: SharePreview("Photo selected", image: currentlyEditablePhoto.image)
                )
            }
        }
        .onChange(of: state.previousPoints) { newSegments in
            if !newSegments.isEmpty {
                processingTask = Task {
                    state.mode = .standardMask
                    await editViewModel.submitForInpainting(state: state)
                }
            }
        }
        .onChange(of: state.removeRects) { val in
            if !val.isEmpty {
                processingTask = Task {
                    let prevMode = state.mode
                    state.mode = .textMask
                    await editViewModel.submitForInpainting(state: state)
                    state.mode = prevMode
                }
            }
        }
        .onDisappear {
            processingTask?.cancel()
        }
        .onAppear {
            state.recognizedRectangles = editViewModel.getTextRects(state: state)
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
    func loadingModelSpinnerView() -> some View {
        if !editViewModel.isModelLoaded {
            ProgressView()
                .controlSize(.regular)
                .tint(.purple)
        }
    }
    
    @ViewBuilder
    func brushSizeOverlay() -> some View {
        if state.isSliderActive {
            Circle()
                .fill(Color.purple.opacity(0.5))
                .frame(width: state.brushSize * state.scrollViewScale, height: state.brushSize * state.scrollViewScale)
        }
    }
    
    @ViewBuilder
    func showSavedImageOverlay() -> some View {
        if state.showingSavedImage {
            ZStack {
                Color.black.opacity(0.5)
                Image(systemName: "photo.badge.checkmark.fill")
                    .foregroundColor(.primary)
                    .font(.title)
            }
        }
    }
    
    func getNewState(for index: Int) -> EditMode {
        let newState: EditMode
        
        switch index {
            case 0:
                newState = .move
            case 1:
                newState = .standardMask
            case 2:
                newState = .lasso
            default:
                newState = .standardMask
        }
        
        return newState
    }
    
    fileprivate func editModePicker() -> Picker<Text, Int, TupleView<(some View, some View)>> {
        Picker("Choose an option", selection: $state.selectedIndex) {
            Text("Move").tag(0)
            Text("Brush").tag(1)
        }
    }
}

#Preview {
    NavigationStack {
        EditView(photoData: UIImage(named: "p1")!.pngData()!)
               .environmentObject(NavigationStore())
               .tint(.primary)
    }
}
