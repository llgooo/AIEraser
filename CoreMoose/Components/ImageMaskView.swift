//
//  ImageMaskView.swift
//  CoreMoose
//
//  Created by m x on 2023/12/5.
//

import SwiftUI

struct ImageMaskingView: View {
    @EnvironmentObject var state: EditState
    
    @State private var isZoomMode = false
    @State private var checkedRectIndexs: [Int] = []
    @State private var dashPhase = 0.0
    @State private var tappedIndex: Int? = nil
    @State private var animationKey = UUID()
    @State private var opacity = 0.5
    
    
    var isModelLoaded: Bool
    
    var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isModelLoaded {
                    return
                }
                guard !state.imageIsBeingProcessed else { return }
                guard value.location.isInBounds(state.imagePresentationState.rectSize) else { return }
                
                state.maskPoints.rectPoints.append(value.location)
                let location = value.location
                let scaledX = location.x * widthScale
                let scaledY = location.y * heightScale
                
                let scaledPoint = CGPoint(x: scaledX, y: scaledY)
                state.maskPoints.scaledPoints.append(scaledPoint)
            }
            .onEnded { _ in
                guard !state.imageIsBeingProcessed else { return }
                guard let imageData = state.imageData else { return }
                
                state.imagePresentationState.imageSize = imageData.getSize()
                state.maskPoints.configuration = SegmentConfiguration(brushSize: state.brushSize * widthScale)
                
                state.previousPoints.append(state.maskPoints)
                state.maskPoints.scaledPoints = []
                state.maskPoints.rectPoints = []
            }
    }
    
    var zoom: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                isZoomMode = true
            }
            .onEnded { _ in
                isZoomMode = false
            }
    }
    
    var heightScale: CGFloat {
        guard let imageData = state.imageData else { return 0.0 }
        return imageData.getSize().height / state.imagePresentationState.rectSize.height
    }
    
    var widthScale: CGFloat {
        guard let imageData = state.imageData else { return 0.0 }
        return imageData.getSize().width / state.imagePresentationState.rectSize.width
    }
    
    var unwrappedDrag: DragGesture {
        guard let gesture = drag as? DragGesture else { return DragGesture() }
        
        return gesture
    }
    
    var adjustedRects: [CGRect] {
        guard let imageData = state.imageData else { return [] }
        let width = imageData.getSize().width
        let height = imageData.getSize().height
        let scaleX = state.imagePresentationState.rectSize.width / width
        let scaleY = state.imagePresentationState.rectSize.height / height
        return state.recognizedRectangles.map { rect in
            CGRect(
                x: rect.origin.x * scaleX,
                y: rect.origin.y * scaleY,
                width: rect.size.width * scaleX,
                height: rect.size.height * scaleY
            )
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(uiImage: UIImage(data: state.imageData!)!)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .gesture(isMoveGesture() ? nil : drag)
                .overlay(
                    showMaskAreaOverlay()
                )
                .overlay(
                    showTextRectOverlay()
                )
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                state.imagePresentationState.rectSize = geometry.size
                            }
                    })
            if state.showingInitialImage && !state.undoImageData.isEmpty{
                Image(uiImage: UIImage(data: state.undoImageData[0])!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
    }
    
    private func isMoveGesture() -> Bool {
        state.mode == .move  || state.mode == .textMask
    }
    
    @ViewBuilder
    func showMaskAreaOverlay() -> some View {
        GestureMaskShape(
            previousPointsSegments: state.previousPoints,
            currentPointsSegment: state.maskPoints
        )
        .stroke(style: StrokeStyle(
            lineWidth: state.brushSize,
            lineCap: .round,
            lineJoin: .round))
        .foregroundColor(.purple.opacity(state.imageIsBeingProcessed ? 0.2 : 0.5))
        .animation(state.imageIsBeingProcessed ? .easeInOut(duration: 0.2).repeatForever(autoreverses: true) : .default, value: state.imageIsBeingProcessed)
    }
    
    @ViewBuilder
    func showTextRectOverlay() -> some View {
        if state.showRecongizedTextRect {
            ForEach(0..<state.recognizedRectangles.count, id: \.self) { index in
                let rect = adjustedRects[index]
                Rectangle()
                    .fill(.purple.opacity(state.imageIsBeingProcessed && tappedIndex == index ? 0.2 : 0.5))
                    .frame(width: rect.size.width, height: rect.size.height)
                    .position(x: rect.midX, y: rect.midY)
                    .onTapGesture {
                        impactFeedback()
                        state.removeRects = [state.recognizedRectangles[index]]
                        tappedIndex = index
                    }
                    .animation(isTextRectAnimating(index) ? .easeInOut(duration: 0.2).repeatForever(autoreverses: true) : .smooth, value: isTextRectAnimating(index))
            }
            .onChange(of: state.imageIsBeingProcessed) { isProcessing in
                if !isProcessing, let indexToRemove = tappedIndex {
                    if indexToRemove < state.recognizedRectangles.count {
                        state.recognizedRectangles.remove(at: indexToRemove)
                    }
                    tappedIndex = nil
                }
            }
        }
    }
    
    private func isTextRectAnimating(_ index: Int) -> Bool {
        tappedIndex == index && state.imageIsBeingProcessed
    }
}
