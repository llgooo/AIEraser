//
//  Utils.swift
//  CoreMoose
//
//  Created by m x on 2023/12/4.
//

import UIKit
import VideoToolbox
import CoreML

func resize(image: UIImage, maxSize: CGFloat, interpolationQuality: CGInterpolationQuality = .high) -> UIImage {
    let size = image.size
    
    // 计算调整大小的比例
    let maxDimension = max(size.width, size.height)
    
    guard maxDimension > maxSize else {
        return image  // 如果图像已经小于最大尺寸，则不进行调整
    }
    let scaleRatio = maxSize / maxDimension
    let newSize = CGSize(width: size.width * scaleRatio, height: size.height * scaleRatio)
    return image.resized(to: newSize)!
}

func readMask(image: UIImage, invert: Bool = true) -> UIImage? {
    guard let grayscaleImage = image.convertToGrayScale() else {
        print("convertToGrayScale error")
        return nil
    }
    
    return invert ? grayscaleImage.invertImage() : grayscaleImage
}


extension CVPixelBuffer {
    var uiImage: UIImage {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(self, options: nil, imageOut: &cgImage)
        return UIImage.init(cgImage: cgImage!)
    }
    
    func convertToImage() -> UIImage? {
        let ciImage = CIImage(cvImageBuffer: self)
        
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}


func croppedImage() -> UIImage? {
    return nil
}

func combineInputAndOutput() -> UIImage? {
    return nil
}

func impactFeedback() {
    if UserDefaults.standard.hapticFeedbackOn {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}


func getMaskedBoundingBox(mask: CGImage, padding: Int) -> CGRect {
    let width = mask.width
    let height = mask.height
    let colorSpace = CGColorSpaceCreateDeviceGray()
    let context = CGContext(data: nil,
                            width: width,
                            height: height,
                            bitsPerComponent: 8,
                            bytesPerRow: width,
                            space: colorSpace,
                            bitmapInfo: CGImageAlphaInfo.none.rawValue)!
    
    context.draw(mask, in: CGRect(x: 0, y: 0, width: width, height: height))
    
    guard let imageData = context.data else { return CGRect.zero }
    
    var xMin = width
    var xMax = 0
    var yMin = height
    var yMax = 0
    
    for y in 0..<height {
        for x in 0..<width {
            let offset = y * width + x
            let intensity = imageData.load(fromByteOffset: offset, as: UInt8.self)
            if intensity > 0 { // Check if the pixel is part of the mask
                xMin = min(xMin, x)
                xMax = max(xMax, x)
                yMin = min(yMin, y)
                yMax = max(yMax, y)
            }
        }
    }
    
    // Apply padding, adjust for image boundaries
    xMin = max(xMin - padding, 0)
    yMin = max(yMin - padding, 0)
    xMax = min(xMax + padding, width)
    yMax = min(yMax + padding, height)
    
    return CGRect(x: xMin, y: yMin, width: xMax - xMin, height: yMax - yMin)
}

func drawProcessedImage(_ processedImage: UIImage, on originalImage: UIImage, at rect: CGRect) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(originalImage.size, false, originalImage.scale)
    originalImage.draw(at: .zero)
    
    processedImage.draw(in: rect)
    
    let resultImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return resultImage
}

func openEmailApp(toEmail: String, subject: String, body: String) {
    guard
        let subject = subject.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
        let body = body.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
        print("Error: Can't encode subject or body.")
        return
    }
    
    let urlString = "mailto:\(toEmail)?subject=\(subject)&body=\(body)"
    let url = URL(string:urlString)!
    
    UIApplication.shared.open(url)
}

func rateApp(rateLink: String) {
    guard let writeReviewURL = URL(string: rateLink) else { fatalError("Expected a valid URL") }
    UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
}


func addWatermarkToImage(_ image: UIImage) -> UIImage {
    let watermarkText = "Core Eraser"
    let font = UIFont.systemFont(ofSize: 40) // 字体大小
    let textColor = UIColor.gray.withAlphaComponent(0.6) // 文字颜色和透明度
    let textAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]

    UIGraphicsBeginImageContextWithOptions(image.size, false, 0)
    image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))

    // 计算文本尺寸
    let textSize = watermarkText.size(withAttributes: textAttributes)
    
    // 设置文本的位置在右下角
    let textRect = CGRect(x: image.size.width - textSize.width - 20, y: image.size.height - textSize.height - 20,
                          width: textSize.width, height: textSize.height)
    
    watermarkText.draw(in: textRect, withAttributes: textAttributes)

    let watermarkedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return watermarkedImage ?? image
}


extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
    
    func localized(withComment:String) -> String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: withComment)
    }
}
