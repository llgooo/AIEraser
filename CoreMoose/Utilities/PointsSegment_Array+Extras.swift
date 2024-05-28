import SwiftUI

extension [PointsSegment] {
    func scaledSegmentsToPath(imageState: ImagePresentationState) -> CGPath {
        var path = Path()
        
        for point in self {
            guard let firstPoint = point.scaledPoints.first else { return path.cgPath }
            
            path.move(to: firstPoint)
            
            path.move(to: firstPoint)
            for pointIndex in 1 ..< point.scaledPoints.count {
                path.addLine(to: point.scaledPoints[pointIndex])
            }
        }
        
        let mirror = CGAffineTransform(scaleX: 1, y: -1)
        let translate = CGAffineTransform(translationX: 0, y: imageState.imageSize.height)
        var concatenated = mirror.concatenating(translate)
        
        if let cgPath = path.cgPath.copy(using: &concatenated) {
            return cgPath
        } else {
            return path.cgPath
        }
    }
}

func transformRectangles(_ recognizedRectanglesScaled: [CGRect], imageState: ImagePresentationState) -> [CGRect] {
    var transformedRectangles = [CGRect]()

    let mirror = CGAffineTransform(scaleX: 1, y: -1)
    let translate = CGAffineTransform(translationX: 0, y: imageState.imageSize.height)
    let concatenated = mirror.concatenating(translate)

    for rect in recognizedRectanglesScaled {
        let transformedRect = rect.applying(concatenated)
        transformedRectangles.append(transformedRect)
    }

    return transformedRectangles
}
