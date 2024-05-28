//
//  MiGanModel.swift
//  CoreMoose
//
//  Created by m x on 2023/12/22.
//

import SwiftUI
import CoreML
import Matft

struct MiGanModel {
    var model: MiGan?
    
    init(model: MiGan?) {
        self.model = model
    }
    
    func Inference(inputImage: UIImage, maskImage: UIImage) async -> UIImage? {
        let startTime = Date()
        defer {
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            print("Inference took \(duration) seconds.")
        }
        
        guard let model = model else { return nil }
        guard let inputTensor = preprocess(img: inputImage, mask: maskImage) else { return nil }
        
        do {
            let output = try model.prediction(input: MiGanInput(x_1: inputTensor))
            guard let  outArray = output.featureValue(for: "var_1268")?.multiArrayValue else { return nil }
            return postprocess(output: outArray, input: inputImage, mask: maskImage)
        } catch {
            print("Error during model inference: \(error.localizedDescription)")
            print("Error details: \(error)")
            return nil
        }
    }
    
    func inferenceClipMode(inputImage: UIImage, maskImage: UIImage) async -> UIImage? {
        let startTime = Date()
        defer {
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            print("Inference took \(duration) seconds.")
        }
        
        guard let model = model else { return nil }
        guard let inputCg = inputImage.cgImage, let maskCg = maskImage.cgImage else { return nil }
        
        // clip the mask and input
        let rect = getMaskedBoundingBox(mask: maskCg, padding: 100)
        
        guard let maskCliped = maskCg.cropping(to: rect), let inputCliped = inputCg.cropping(to: rect) else {
            return nil
        }
        
        // cliped image to inputTenser
        guard let inputTensor = preprocess(img: UIImage(cgImage: inputCliped), mask: UIImage(cgImage: maskCliped)) else {
            return nil
        }
        
        do {
            let output = try model.prediction(input: MiGanInput(x_1: inputTensor))
            let outArray = output.featureValue(for: "var_1268")?.multiArrayValue
            guard let ret = postprocessBlendMode(output: outArray!, input: UIImage(cgImage: inputCliped), mask: UIImage(cgImage: maskCliped)) else {
                return nil
            }
            return drawProcessedImage(ret, on: inputImage, at: rect)
        } catch {
            print("Error during model inference: \(error.localizedDescription)")
            print("Error details: \(error)")
            return nil
        }
    }
    
    func inputImagePreProcess(input: UIImage, resolution: Int) -> UIImage? {
        // Convert input image to RGB format
        guard let imgRGB = input.convertToRGB() else {
            return nil
        }
        // Resize the RGB image to have the maximum dimension equal to the specified resolution
        let imgResized = resize(image: imgRGB, maxSize: CGFloat(resolution))
        // Further resize the image to the exact target resolution with high interpolation quality
        return imgResized.resized(to: CGSize(width: resolution, height: resolution), quality: .high)
    }
    
    func maskPreProcess(mask: UIImage, resolution: Int) -> UIImage? {
        // Convert mask image to grayscale and invert it
        guard let maskGrayScale = readMask(image: mask, invert: true) else {
            return nil
        }
        // Resize the grayscale mask to have the maximum dimension equal to the specified resolution
        let maskResized = resize(image: maskGrayScale, maxSize: CGFloat(resolution))
        // Further resize the mask to the exact target resolution with no interpolation (for sharp edges)
        return maskResized.resized(to: CGSize(width: resolution, height: resolution), quality: .none)
        
    }
    
    func preprocess(img: UIImage, mask: UIImage) -> MLMultiArray? {
        // Preprocess the input and mask images to a specified resolution (512 in this case)
        guard let inputResized = inputImagePreProcess(input: img, resolution: 512),
              let maskResized = maskPreProcess(mask: mask, resolution: 512) else {
            return nil
        }
        // Convert the preprocessed images to Matft's MfArray format for further processing
        // Extracts the RGB channels from the input image
        let imgNp = Matft.image.cgimage2mfarray(inputResized.cgImage!).astype(.Float)[Matft.all, Matft.all , 0~<3]
        // Extracts the grayscale channel from the mask image
        let maskNp = Matft.image.cgimage2mfarray(maskResized.cgImage!).astype(.Float)[Matft.all, Matft.all , 0~<1]
        
        // Normalize the input image data to a range of [-1, 1]
        let imgNp1 = (imgNp * 2) - 1
        
        // Combine the normalized input image and mask, then rearrange and expand dimensions
        // to match CoreML model's expected input format
        let combined = Matft.concatenate([(maskNp - 0.5), imgNp1 * maskNp], axis: 2)
            .transpose(axes: [2, 0, 1])
            .expand_dims(axis: 0)
        
        return try? combined.toMLMultiArray()
    }
    
    func postprocess(output: MLMultiArray, input: UIImage, mask: UIImage) -> UIImage? {
        // Attempt to create a buffer pointer from the MLMultiArray output
        guard let bPtr = try? UnsafeBufferPointer<Float>(output) else {
            return nil
        }
        
        // Convert the buffer pointer to a MfArray for processing
        // Normalizes and clips the array values, then converts to UInt8
        let outputMfArray = (MfArray(Array(bPtr), mftype: .Float, shape: [1, 3, 512, 512])
            .reshape([3, 512, 512])
            .transpose(axes: [1, 2, 0]) * 0.5 + 0.5)
            .clip(min: 0, max: 1)
            .astype(.UInt8) * 255
        
        // Convert the processed MfArray back to MLMultiArray
        guard let outputMLMutilArray = try? outputMfArray.toMLMultiArray() else {
            return nil
        }
        
        // Create a UIImage from the MLMultiArray
        let outputImg = outputMLMutilArray.image(axes: (2, 0, 1))
        
        let orginImg = resize(image: input, maxSize: CGFloat(512))
        
        // Process the mask image
        guard let maskGrayScale = readMask(image: mask, invert: true) else {
            return nil
        }
        let mask = resize(image: maskGrayScale, maxSize: CGFloat(512))
        // Resize the output image to match the original image's dimensions
        let outputResized = Matft.image.resize(Matft.image.cgimage2mfarray((outputImg?.cgImage)!),
                                               width: Int(orginImg.size.width),
                                               height: Int(orginImg.size.height))[Matft.all, Matft.all, 0~<3] * 255
        
        // Convert the original and mask images to MfArray for blending
        let orginNp = Matft.image.cgimage2mfarray((orginImg.cgImage)!).astype(.Float)[Matft.all, Matft.all, 0~<3] * 255
        let maskResizedNp = Matft.image.cgimage2mfarray((mask.cgImage)!).astype(.Float)[Matft.all, Matft.all , 0~<3]
        
        // Blend the original image with the output image using the mask
        let composedImg = (orginNp * maskResizedNp + outputResized * (1 - maskResizedNp)).astype(.UInt8)
        
        // Convert the blended image back to MLMultiArray
        guard let composedImgMLMutilArray = try? composedImg.toMLMultiArray() else {
            return nil
        }
        
        // Convert the final blended MLMultiArray to a UIImage and return
        return composedImgMLMutilArray.image(axes: (2, 0, 1))
    }
    
    func postprocessBlendMode(output: MLMultiArray, input: UIImage, mask: UIImage) -> UIImage? {
        guard let bufferPointer = try? UnsafeBufferPointer<Float32>(output) else {
            return nil
        }
        
        // Assuming you're using a library that provides the following functionality
        let outputMfArray = (MfArray(Array(bufferPointer), mftype: .Float, shape: [1, 3, 512, 512])
            .reshape([3, 512, 512])
            .transpose(axes: [1, 2, 0]) * 0.5 + 0.5)
            .clip(min: 0, max: 1)
            .astype(.UInt8) * 255
        
        guard let outputMLMutilArray = try? outputMfArray.toMLMultiArray(), let outputImg = outputMLMutilArray.image(axes: (2, 0, 1)) else {
            return nil
        }
        
        // Resize the output image to match the input image size
        guard let resizedOutputImage = outputImg.resized(to: input.size) else {
            return nil
        }
        
        // Blend the resized output image and the input image using the resized mask
        return blend(baseImage: input, with: resizedOutputImage, using: mask)
    }
    
    // Helper method to blend images with a mask
    func blend(baseImage: UIImage, with overlayImage: UIImage, using mask: UIImage) -> UIImage? {
        let size = baseImage.size
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let blendedImage = renderer.image { context in
            // 绘制基础图像
            baseImage.draw(at: .zero)
            
            // 调整坐标系统以匹配CGImage
            context.cgContext.translateBy(x: 0, y: size.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            
            // 应用蒙版
            guard let maskCGImage = mask.cgImage else { return }
            context.cgContext.clip(to: CGRect(origin: .zero, size: size), mask: maskCGImage)
            
            // 绘制覆盖图像
            guard let overlayCGImage = overlayImage.cgImage else { return }
            context.cgContext.draw(overlayCGImage, in: CGRect(origin: .zero, size: size))
        }
        return blendedImage
    }
    
    func showCombinedImage(combined_np: MfArray) -> UIImage? {
        let denormalizedNp = (combined_np + 1) / 2 * 255
        let denormalizedNpInt = denormalizedNp.astype(.UInt8)
        
        let  npArray = Matft.transpose(denormalizedNpInt[0], axes: [1, 2, 0])
        guard let  imgMLMutilArray = try? npArray.toMLMultiArray() else {
            return nil
        }
        
        return imgMLMutilArray.image(axes: (2, 0, 1))
    }
}
