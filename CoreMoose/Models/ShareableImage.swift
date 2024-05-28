//
//  ShareableImage.swift
//  CoreMoose
//
//  Created by m x on 2023/12/5.
//

import SwiftUI

struct ShareableImage: Transferable {
  static var transferRepresentation: some TransferRepresentation {
    ProxyRepresentation(exporting: \.image)
  }

  public var image: Image
  public var caption: String
}
