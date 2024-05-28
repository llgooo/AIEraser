//
//  UpscaleModel.swift
//  CoreMoose
//
//  Created by m x on 2023/12/26.
//

import SwiftUI
import CoreML
import Vision

struct UpscalerModel {
    func makeSrReuest() -> VNCoreMLRequest? {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndGPU
            let model = try Upscaler512(configuration: config).model
            let vnModel = try VNCoreMLModel(for: model)
            let request = VNCoreMLRequest(model: vnModel)
            request.imageCropAndScaleOption = .scaleFill
            return request
        } catch let error {
            print("model initialize error: \(error)")
            return nil
        }
    }
    
    func Inference(inputImage: UIImage) async -> UIImage? {
        guard let srReq = makeSrReuest() else {
            return nil
        }
        guard let ciInputImage = CIImage(image: inputImage) else {
            print("Invalid input image")
            return nil
        }
        
        let handler = VNImageRequestHandler(ciImage: ciInputImage)
        do {
            try handler.perform([srReq])
            guard let result = srReq.results?.first as? VNPixelBufferObservation else {
                print("No results from srRequest")
                return nil
            }
            
            let srCIImage = CIImage(cvPixelBuffer: result.pixelBuffer)
            let context = CIContext(options: nil)
            guard let cgImage = context.createCGImage(srCIImage, from: srCIImage.extent) else {
                print("Failed to create CGImage from CIImage")
                return nil
            }
            
            guard let cgImageResize = cgImage.resize(size: CGSize(width: inputImage.size.width, height: inputImage.size.height)) else {
                print("Failed to resize CGImage")
                return nil
            }
            
            return UIImage(cgImage: cgImageResize)
        } catch {
            print("Error performing super-resolution inference: \(error)")
            return nil
        }
    }
}
