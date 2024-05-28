//
//  CGImage+Extras.swift
//  CoreMoose
//
//  Created by m x on 2023/12/5.
//

import Accelerate
import CoreGraphics
import UIKit

extension CGImage {
    var bounds: CGRect {
        CGRect(x: 0, y: 0, width: width, height: height)
    }
    
    public func createMaskFromLassoPath(_ path: CGPath, lineWidth: CGFloat) -> CGImage? {
        let width = width
        let height = height
        
        guard let bmContext = CGContext.ARGBBitmapContext(width: width, height: height, withAlpha: true) else {
            return nil
        }
        
        bmContext.setFillColor(UIColor.yellow.cgColor)
        bmContext.setStrokeColor(UIColor.yellow.cgColor)
        bmContext.setLineWidth(lineWidth)
        bmContext.setLineCap(.round)
        bmContext.setLineJoin(.round)
        bmContext.addPath(path)
        bmContext.drawPath(using: .fillStroke)
        
        let image = bmContext.makeImage()
        
        let result = image?.convertToGrayScale()
        
        return result
    }
    
    public func createMaskFromPath(_ path: CGPath, lineWidth: CGFloat) -> CGImage? {
        let width = self.width
        let height = self.height
        guard let bmContext = CGContext.ARGBBitmapContext(width: width, height: height, withAlpha: true) else {
            return nil
        }
        
        bmContext.setStrokeColor(UIColor.yellow.cgColor)
        bmContext.setLineWidth(lineWidth)
        bmContext.setLineCap(.round)
        bmContext.setLineJoin(.round)
        bmContext.addPath(path)
        bmContext.drawPath(using: .stroke)
        
        let image = bmContext.makeImage()
        
        let result = image?.convertToGrayScale()
        
        return result
    }
    
    public func createMaskFromRectangles(_ rectangles: [CGRect], lineWidth: CGFloat) -> CGImage? {
        let width = self.width
        let height = self.height
        guard let bmContext = CGContext.ARGBBitmapContext(width: width, height: height, withAlpha: true) else {
            return nil
        }
        bmContext.translateBy(x: 0, y: CGFloat(height))
        bmContext.scaleBy(x: 1.0, y: -1.0)
        
        bmContext.setStrokeColor(UIColor.white.cgColor)
        bmContext.setFillColor(UIColor.white.cgColor)
        bmContext.setLineWidth(lineWidth)
        bmContext.setLineCap(.round)
        bmContext.setLineJoin(.round)
        
        for rectangle in rectangles {
            bmContext.addRect(rectangle)
            bmContext.fill(rectangle)
            bmContext.stroke(rectangle)
        }
        let image = bmContext.makeImage()
        
        let result = image?.convertToGrayScale()
        
        return result
    }
    
    
    public func convertToGrayScale() -> CGImage? {
        guard let format = vImage_CGImageFormat(bitsPerComponent: 8,
                                                bitsPerPixel: 32,
                                                colorSpace: CGColorSpaceCreateDeviceRGB(),
                                                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
                                                renderingIntent: .defaultIntent) else {
            return nil
        }
        
        guard var sourceBuffer = try? vImage_Buffer(cgImage: self, format: format) else {
            return nil
        }
        
        // 确保在函数结束时释放sourceBuffer
        defer {
            free(sourceBuffer.data)
        }
        
        let preBias: [Int16] = [0, 0, 0, 0]
        let postBias: Int32 = 0
        let divisor: Int32 = 0x1000
        let fDivisor = Float(divisor)
        
        let redCoefficient: Float = 1
        let greenCoefficient: Float = 1
        let blueCoefficient: Float = 1
        
        var coefficientsMatrix = [
            Int16(redCoefficient * fDivisor),
            Int16(greenCoefficient * fDivisor),
            Int16(blueCoefficient * fDivisor),
        ]
        
        guard var destinationBuffer = try? vImage_Buffer(width: width,
                                                         height: height,
                                                         bitsPerPixel: 8) else {
            return nil
        }
        
        // 确保在函数结束时释放destinationBuffer
        defer {
            free(destinationBuffer.data)
        }
        
        vImageMatrixMultiply_ARGB8888ToPlanar8(
            &sourceBuffer,
            &destinationBuffer,
            &coefficientsMatrix,
            divisor,
            preBias,
            postBias,
            vImage_Flags(kvImageNoFlags))
        
        guard let monoFormat = vImage_CGImageFormat(bitsPerComponent: 8,
                                                    bitsPerPixel: 8,
                                                    colorSpace: CGColorSpaceCreateDeviceGray(),
                                                    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                                                    renderingIntent: .defaultIntent) else {
            return nil
        }
        
        let result = try? destinationBuffer.createCGImage(format: monoFormat)
        return result
    }
    
    public func clipedByBounds(_ expandedBounds: CGRect, height: Int) -> CGImage? {
        let cropSize: CGSize = CGSize(width: 512, height: 512)
        let clippedExpandedBounds = self.bounds.intersection(expandedBounds)
        let clippedExpandedBoundsWidthDeficiency = cropSize.width - clippedExpandedBounds.width
        let clippedExpandedBoundsHeightDeficiency = cropSize.height - clippedExpandedBounds.height
        let expandedMaskBounds = CGRect(x: clippedExpandedBounds.origin.x - clippedExpandedBoundsWidthDeficiency,
                                        y: clippedExpandedBounds.origin.y - clippedExpandedBoundsHeightDeficiency,
                                        width: cropSize.width,
                                        height: cropSize.height)
        return self.cropping(to: expandedMaskBounds)
    }
    
    func getExpandedBounds() ->CGRect? {
        let cropSize: CGSize = CGSize(width: 512, height: 512)
        
        guard let maskBounds = boundingRectOfMaskImage(self) else {
            return nil
        }
        let expandedBoundsOrign = CGPoint(x: max(floor(maskBounds.center.x - cropSize.width / 2), 0),
                                          y: max(floor(maskBounds.center.y - cropSize.height / 2), 0))
        return CGRect(origin: expandedBoundsOrign, size: cropSize)
    }
}


func boundingRectOfMaskImage(_ cgImage: CGImage) -> CGRect? {
    let width = cgImage.width
    let height = cgImage.height
    let colorSpace = CGColorSpaceCreateDeviceGray()
    var minX = width, minY = height, maxX = 0, maxY = 0
    
    guard let context = CGContext(data: nil,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: width,
                                  space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
        return nil
    }
    
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    guard let data = context.data else { return nil }
    
    for x in 0 ..< width {
        for y in 0 ..< height {
            let pixelIndex = x + y * width
            let pixel = data.load(fromByteOffset: pixelIndex, as: UInt8.self)
            if pixel != 0 { // Non-transparent pixel
                minX = min(minX, x)
                maxX = max(maxX, x)
                minY = min(minY, y)
                maxY = max(maxY, y)
            }
        }
    }
    
    return minX < maxX && minY < maxY ? CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY) : nil
}
