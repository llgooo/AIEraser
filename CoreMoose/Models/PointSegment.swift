//
//  PointSegment.swift
//  CoreMoose
//
//  Created by m x on 2023/12/5.
//

import Foundation

struct PointsSegment: Equatable, Identifiable {
  var id = UUID()
  var configuration: SegmentConfiguration

  var rectPoints: [CGPoint]
  var scaledPoints: [CGPoint]
}
