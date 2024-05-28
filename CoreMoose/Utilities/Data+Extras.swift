//
//  Data+Extras.swift
//  CoreMoose
//
//  Created by m x on 2023/12/5.
//

import CoreGraphics
import Foundation
import UIKit

extension Data {
  func getSize() -> CGSize {
    let image = UIImage(data: self)
    if let cgImage = image?.cgImage {
      return CGSize(width: cgImage.width, height: cgImage.height)
    }

    return CGSize(width: 0, height: 0)
  }
}
