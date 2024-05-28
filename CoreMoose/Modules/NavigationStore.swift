//
//  NavigationStore.swift
//  CoreMoose
//
//  Created by m x on 2023/12/4.
//

import SwiftUI

class NavigationStore: ObservableObject {
    @Published var paths: [Route] = []
    
    func navigateToPath(_ route: Route) {
        paths.append(route)
    }
    
    func dismissView() {
        if paths.isEmpty {
            return
        }
        paths.removeLast()
    }
}
