//
//  CGPoint+Extras.swift
//  CoreMoose
//
//  Created by m x on 2023/12/5.
//

import Foundation

extension CGPoint {
  func isInBounds(_ bounds: CGSize) -> Bool {
    x >= 0 &&
      y >= 0 &&
      x <= bounds.width &&
      y <= bounds.height
  }
}
