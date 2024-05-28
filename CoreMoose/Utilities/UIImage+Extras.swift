//
//  UIImage+Extras.swift
//  CoreMoose
//
//  Created by m x on 2023/12/5.
//
import UIKit

extension UIImage {
    func resized(to targetSize: CGSize, quality: CGInterpolationQuality = .high) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        
        return renderer.image { context in
            context.cgContext.interpolationQuality = quality
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    func convertToRGB() -> UIImage? {
        // Define the RGB color space
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // Create a new bitmap graphics context
        guard let context = CGContext(data: nil,
                                      width: Int(self.cgImage!.width),
                                      height: Int(self.cgImage!.height),
                                      bitsPerComponent: 8, // 8 bits per component in RGB
                                      bytesPerRow: 0, // Let Core Graphics determine the row bytes
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        
        // Draw the image into the context
        if let cgImage = self.cgImage {
            context.draw(cgImage, in: CGRect(origin: CGPoint.zero, size: CGSize(width: self.cgImage!.width, height: self.cgImage!.height)))
        } else {
            return nil
        }
        
        // Extract the image from the context
        guard let newCGImage = context.makeImage() else { return nil }
        
        // Return a new UIImage
        return UIImage(cgImage: newCGImage)
    }
    
    
    func convertToGrayScale() -> UIImage? {
        // 定义灰度颜色空间
        let colorSpace = CGColorSpaceCreateDeviceGray()
        
        // 创建一个新的bitmap图像上下文
        let context = CGContext(data: nil,
                                width: Int(self.cgImage!.width),
                                height: Int(self.cgImage!.height),
                                bitsPerComponent: 8, // 灰度图每个颜色分量8位
                                bytesPerRow: 0,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.none.rawValue) // 灰度图不包含alpha分量
        
        // 确保上下文创建成功
        guard let cgContext = context else { return nil }
        
        // 绘制原始图片到灰度上下文
        if let cgImage = self.cgImage {
            cgContext.draw(cgImage, in: CGRect(origin: CGPoint.zero, size: self.size))
        }
        
        // 从灰度上下文中获取转换后的图片
        guard let grayImage = cgContext.makeImage() else { return nil }
        
        // 返回灰度图
        return UIImage(cgImage: grayImage)
    }
    
    
    func invertImage() -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }
        
        // 创建反转滤镜
        if let filter = CIFilter(name: "CIColorInvert") {
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            
            // 获取滤镜输出
            guard let outputCIImage = filter.outputImage else { return nil }
            
            // 创建CIContext对象
            let context = CIContext(options: nil)
            
            // 创建CGImage
            if let cgImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return nil
    }
    
    /// Fix image orientaton to protrait up
    func fixedOrientation() -> UIImage? {
        guard imageOrientation != UIImage.Orientation.up else {
            // This is default orientation, don't need to do anything
            return self.copy() as? UIImage
        }
        
        guard let cgImage = self.cgImage else {
            // CGImage is not available
            return nil
        }
        
        guard let colorSpace = cgImage.colorSpace, let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil // Not able to create CGContext
        }
        
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        switch imageOrientation {
            case .down, .downMirrored:
                transform = transform.translatedBy(x: size.width, y: size.height)
                transform = transform.rotated(by: CGFloat.pi)
            case .left, .leftMirrored:
                transform = transform.translatedBy(x: size.width, y: 0)
                transform = transform.rotated(by: CGFloat.pi / 2.0)
            case .right, .rightMirrored:
                transform = transform.translatedBy(x: 0, y: size.height)
                transform = transform.rotated(by: CGFloat.pi / -2.0)
            case .up, .upMirrored:
                break
            @unknown default:
                fatalError("Missing...")
                break
        }
        
        // Flip image one more time if needed to, this is to prevent flipped image
        switch imageOrientation {
            case .upMirrored, .downMirrored:
                transform = transform.translatedBy(x: size.width, y: 0)
                transform = transform.scaledBy(x: -1, y: 1)
            case .leftMirrored, .rightMirrored:
                transform = transform.translatedBy(x: size.height, y: 0)
                transform = transform.scaledBy(x: -1, y: 1)
            case .up, .down, .left, .right:
                break
            @unknown default:
                fatalError("Missing...")
                break
        }
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
            case .left, .leftMirrored, .right, .rightMirrored:
                ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
            default:
                ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
                break
        }
        
        guard let newCGImage = ctx.makeImage() else { return nil }
        return UIImage.init(cgImage: newCGImage, scale: 1, orientation: .up)
        
    }
    
    var isGrayscale: Bool {
        guard let cgImage = self.cgImage else { return false }
        guard let colorSpace = cgImage.colorSpace else { return false }
        
        let colorSpaceModel = colorSpace.model
        return colorSpaceModel == .monochrome
    }
    
    var withFixedOrientation: UIImage? {
        switch imageOrientation {
        case .up:
            return self
        default:
            let renderer = UIGraphicsImageRenderer(size: size, format: .init(for: traitCollection))
            
            return renderer.image { _ in
                draw(in: CGRect(origin: .zero, size: size))
            }
        }
    }
}
