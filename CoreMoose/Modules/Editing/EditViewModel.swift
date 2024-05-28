//
//  EditViewModel.swift
//  CoreMoose
//
//  Created by m x on 2023/12/5.
//

import SwiftUI
import Matft
import CoreML
import Vision

class EditViewModel: ObservableObject {
    @Published var isModelLoaded = false

    private var lamaModel: LaMa?
    private var miGanModel: MiGan?
    
    init() {
        let modelType = UserDefaults.standard.currentModelType
        Task { @MainActor in
            let startTime = Date()
            switch modelType {
                case .MiGan:
                    try? await self.loadMiGanModel()
                case .LaMa:
                    try? await self.loadLaMaModel()
                case .Upscaler:
                    break
            }
            isModelLoaded = true
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            print("load model \(modelType.rawValue) took \(duration) seconds.")
        }
    }
    
    func loadLaMaModel() async throws {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndGPU
        config.allowLowPrecisionAccumulationOnGPU = true
        self.lamaModel = try await LaMa.load(configuration: config)
    }
    
    func loadMiGanModel() async throws{
        let config = MLModelConfiguration()
        config.computeUnits = .all
        config.allowLowPrecisionAccumulationOnGPU = true
        self.miGanModel = try await MiGan.load(configuration: config)
    }
    
    @MainActor
    func submitForInpainting(state: EditState) async {
        if (state.modelType == .LaMa || state.modelType == .MiGan)  && !isModelLoaded {
            return
        }
        
        let maskData: Data?
        switch state.mode {
            case .textMask:
                maskData = getMaskDataFromTextRects(state: state)
            case .lasso:
                maskData = getLassoMaskDataFromPath(state: state)
            default:
                maskData = getMaskImageDataFromPath(state: state)
        }
        
        guard let data = maskData else { return }
        
        state.imageIsBeingProcessed = true
        
        guard let originalImageData = state.imageData,
              let input = UIImage(data: originalImageData),
              let mask = UIImage(data: data) else {
            return
        }
        
        switch state.modelType {
            case .LaMa:
                let lama = LaMaModel(model: lamaModel)
                guard let res = await lama.Inference(inputImage: input, maskImage: mask) else {
                    print("Lama model inference error")
                    return
                }
                self.processInpaintingResponse(state: state, data: res.pngData()!)
            case .MiGan:
                let migan = MiGanModel(model: miGanModel)
                guard let res = await migan.inferenceClipMode(inputImage: input, maskImage: mask) else {
                    print("MiGan model inference error")
                    return
                }
                self.processInpaintingResponse(state: state, data: res.pngData()!)
            case .Upscaler:
                let upscler = UpscalerModel()
                guard let res = await upscler.Inference(inputImage: input) else {
                    print("Upscler model inference error")
                    return
                }
                self.processInpaintingResponse(state: state, data: res.pngData()!)
        }
    }
    
    func processInpaintingResponse(state: EditState, data: Data) {
        guard let currentImageData = state.imageData else { return }
        
        state.imageIsBeingProcessed = false
        state.redoImageData.removeAll()
        state.undoImageData.append(currentImageData)
        state.imageData = data
        state.previousPoints.removeAll()
    }
    
    func getMaskImageDataFromPath(state: EditState) -> Data? {
        guard let currentImageData = state.imageData else { return nil }
        
        let image = UIImage(data: currentImageData)
        let scaledSegments = state.previousPoints.scaledSegmentsToPath(imageState: state.imagePresentationState)
        
        if  let cgImage = image?.cgImage,
            let newCGImage = cgImage.createMaskFromPath(scaledSegments, lineWidth: state.maskPoints.configuration.brushSize) {
            
            let newImage = UIImage(cgImage: newCGImage)
            if let newData = newImage.pngData() {
                if state.isDebugMode {
                    state.undoImageData.append(newData)
                }
                return newData
            }
        }
        return nil
    }
    
    func getLassoMaskDataFromPath(state: EditState) -> Data? {
        guard let currentImageData = state.imageData else { return nil }
        
        let image = UIImage(data: currentImageData)
        let scaledSegments = state.previousPoints.scaledSegmentsToPath(imageState: state.imagePresentationState)
        
        if let cgImage = image?.cgImage,
           let newCGImage = cgImage.createMaskFromLassoPath(scaledSegments, lineWidth: state.brushSize) {
            
            let newImage = UIImage(cgImage: newCGImage)
            if let newData = newImage.pngData() {
                if state.isDebugMode {
                    state.undoImageData.append(newData)
                }
                return newData
            }
        }
        return nil
    }
    
    func getMaskDataFromTextRects(state: EditState) -> Data? {
        guard let currentImageData = state.imageData else { return nil }
        
        let image = UIImage(data: currentImageData)

        if let cgImgae = image?.cgImage,
           let newCGImage = cgImgae.createMaskFromRectangles(state.removeRects, lineWidth: 1) {
            
            let newImage = UIImage(cgImage: newCGImage)
            if let newData = newImage.pngData() {
                if state.isDebugMode {
                    state.undoImageData.append(newData)
                }
                return newData
            }
        }
        return nil
    }
    
    func getTextRects(state: EditState) -> [CGRect] {
        guard let currentImageData = state.imageData else { return [] }

        guard let image = UIImage(data: currentImageData),
              let cgImage = image.cgImage else { return [] }
        
        var rects: [CGRect] = []
        
        do {
            let request = VNRecognizeTextRequest()
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            request.automaticallyDetectsLanguage = true
            request.recognitionLevel = .accurate
            
            try requestHandler.perform([request])
            
            guard let observations = request.results else {
                return []
            }
            
            for observation in observations {
                let boundingBox = observation.boundingBox
                
                var transform = CGAffineTransform.identity
                transform = transform.scaledBy(x: image.size.width, y: -image.size.height)
                transform = transform.translatedBy(x: 0, y: -1)
                let transformedRect = boundingBox.applying(transform)
                rects.append(transformedRect)
            }
        } catch {
            print("Error performing text recognition: \(error.localizedDescription)")
        }
        
        return rects
    }

    func analyzeImage(state: EditState) -> [CGRect] {
        guard let currentImageData = state.imageData,
              let image = UIImage(data: currentImageData),
              let cgImage = image.cgImage else { return [] }

        var rects: [CGRect] = []

        do {
            // Create requests
            let textRequest = VNRecognizeTextRequest()
            textRequest.automaticallyDetectsLanguage = true
            textRequest.recognitionLevel = .accurate

            let barcodeRequest = VNDetectBarcodesRequest()
            barcodeRequest.symbologies = [.qr] // You can add more symbologies if needed
            
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            try requestHandler.perform([textRequest, barcodeRequest])

            // Process text observations
            if let textObservations = textRequest.results{
                for observation in textObservations {
                    let transformedRect = transformRect(boundingBox: observation.boundingBox, imageSize: image.size)
                    rects.append(transformedRect)
                }
            }

            // Process barcode observations
            if let barcodeObservations = barcodeRequest.results {
                for observation in barcodeObservations {
                    var transformedRect = transformRect(boundingBox: observation.boundingBox, imageSize: image.size)
                    transformedRect = transformedRect.insetBy(dx: -10, dy: -10)
                    rects.append(transformedRect)
                }
            }
        } catch {
            print("Error performing image analysis: \(error.localizedDescription)")
        }

        return rects
    }

    private func transformRect(boundingBox: CGRect, imageSize: CGSize) -> CGRect {
        var transform = CGAffineTransform.identity
        transform = transform.scaledBy(x: imageSize.width, y: -imageSize.height)
        transform = transform.translatedBy(x: 0, y: -1)
        
        return boundingBox.applying(transform)
    }
    
    func createTextOverlay(for image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        do {
            let request = VNRecognizeTextRequest()
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            request.automaticallyDetectsLanguage = true
            request.recognitionLevel = .accurate
            
            try requestHandler.perform([request])
            
            guard let observations = request.results else {
                return nil
            }
            
            return drawTextOverlay(on: image, using: observations)
        } catch {
            print("Error performing text recognition: \(error.localizedDescription)")
            return nil
        }
    }
    
    func drawTextOverlay(on image: UIImage, using observations: [VNRecognizedTextObservation]) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        image.draw(in: CGRect(origin: .zero, size: image.size))
        
        context.setStrokeColor(UIColor.purple.cgColor)
        context.setLineWidth(2)
        
        for observation in observations {
            let boundingBox = observation.boundingBox
            
            // Transform the bounding box to the UIKit coordinate system
            var transform = CGAffineTransform.identity
            transform = transform.scaledBy(x: image.size.width, y: -image.size.height)
            transform = transform.translatedBy(x: 0, y: -1)
            let transformedRect = boundingBox.applying(transform)
            
            context.stroke(transformedRect)
        }
        
        let overlayedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return overlayedImage
    }
    
    func featurePrintFromImage(image: UIImage) -> VNFeaturePrintObservation? {
        let requestHandler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        do {
            let request = VNGenerateImageFeaturePrintRequest()
            try requestHandler.perform([request])
            return request.results?.first as? VNFeaturePrintObservation
        } catch {
            return nil
        }
    }
    
    func recognizeText(image: UIImage) -> String? {
        guard let cgImage = image.cgImage else { return nil }
        
        do {
            let request = VNRecognizeTextRequest()
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            request.automaticallyDetectsLanguage = true
            request.recognitionLevel = .accurate
            
            try requestHandler.perform([request])
            
            guard let observations = request.results else {
                return nil
            }
            
            return observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
        } catch {
            return nil
        }
    }
}
