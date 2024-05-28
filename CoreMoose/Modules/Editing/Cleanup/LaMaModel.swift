//
//  LaMaModel.swift
//  CoreMoose
//
//  Created by m x on 2023/12/22.
//
import SwiftUI
import CoreML

struct LaMaModel {
    let resolution = CGSize(width: 512, height: 512)
    var model: LaMa?
    
    init(model: LaMa?) {
        self.model = model
    }
    
    func Inference(inputImage: UIImage, maskImage: UIImage) async -> UIImage? {
        let startTime = Date()
        defer {
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            print("Inference took \(duration) seconds.")
        }
        
        guard let model = model else {
            print("LaMa model is not loaded")
            return nil
        }
        
        do {
            guard let inputCg = inputImage.cgImage, let maskCg = maskImage.cgImage else {
                return nil
            }
            // clip image
            let rect = getMaskedBoundingBox(mask: maskCg, padding: 100)
            guard let maskCliped = maskCg.cropping(to: rect), let inputCliped = inputCg.cropping(to: rect) else {
                return nil
            }
            // resize fit to the model input
            guard let maskResized = maskCliped.resize(size: resolution), let inputResized = inputCliped.resize(size: resolution) else {
                return nil
            }
            
            // model prediction
            let result = try model.prediction(input: LaMaInput(imageWith: inputResized, maskWith: maskResized))
            
            // resize model prdiction result to the rect size
            let resultResized = result.output.uiImage.resized(to: CGSize(width: rect.width, height: rect.height))!
            
            // upscale the result
            // Upscaler operation - assuming upscalerModel has a method called 'Upscale'
            //            guard let upscalerModel = upscalerModel else { return nil }
            //            let upscaledImage = try await upscalerModel.prediction(input: Upscaler512Input(inputWith: resultResized.cgImage!))
            
            // write the process result to the input image
            return drawProcessedImage(resultResized, on: inputImage, at: rect)
            
        } catch {
            print("Inferecne error: \(error)")
            return nil
        }
    }
    
    func combionResult(output: UIImage, input: UIImage, mask: UIImage, expandedBounds: CGRect) -> UIImage? {
        guard let outputCg = output.cgImage else {
            return nil
        }
        let size = input.size
        let render = UIGraphicsImageRenderer(size: size)
        
        return render.image { context in
            // draw the base image
            input.draw(at: .zero)
            
            // ajust the coordinate system to match CGImage
            context.cgContext.translateBy(x: 0, y: size.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            
            // draw the output image
            context.cgContext.draw(outputCg, in: expandedBounds)
        }
    }
}
