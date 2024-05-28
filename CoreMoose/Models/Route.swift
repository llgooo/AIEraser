//
//  Route.swift
//  CoreMoose
//
//  Created by m x on 2023/12/4.
//

import Foundation

enum Route: Hashable {
    case editPhoto(Data)
    case upscalePhoto(Data)
}
