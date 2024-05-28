//
//  EditState.swift
//  CoreMoose
//
//  Created by m x on 2023/12/5.
//

import SwiftUI
import Photos

class EditState: ObservableObject {
    
    // MARK: Lifecycle
    
    init(photoData: Data) {
        imageData = photoData
    }
    
    // MARK: Internal
    
    @Published var mode: EditMode = .standardMask
    @Published var modelType: ModelType = UserDefaults.standard.currentModelType
    @Published var imagePresentationState: ImagePresentationState = .init(imageSize: .zero, rectSize: .zero)
    @Published var imageData: Data? = nil
    @Published var undoImageData: [Data] = []
    @Published var redoImageData: [Data] = []
    @Published var maskPoints: PointsSegment = .init(
        configuration: SegmentConfiguration(brushSize: 30),
        rectPoints: [],
        scaledPoints: [])
    @Published var previousPoints: [PointsSegment] = []
    @Published var brushSize: Double = 70.0
    @Published var baseBrushSize = 70.0
    @Published var isSliderActive = false
    @Published var scrollViewScale: CGFloat = 1.0
    @Published var imageIsBeingProcessed = false
    @Published var selectedIndex = 1
    @Published var showingInitialImage = false
    @Published var showingSavedImage = false
    
    @Published var showRecongizedTextRect = false
    @Published var recognizedRectangles: [CGRect] = []
    @Published var removeRects: [CGRect] = []
    
    @Published var isDebugMode = false
}


extension EditState {
    func saveImageToPhotos() {
        guard let imageData = self.imageData,
              var image = UIImage(data: imageData) else { return }
        
        if !UserDefaults.standard.isPro {
            image = addWatermarkToImage(image)
        }
        
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.showingSavedImage = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            self.showingSavedImage = false
                        }
                    }
                } else {
                    // Handle unauthorized access, possibly alert the user
                }
            }
        }
    }
}
