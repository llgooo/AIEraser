//
//  ZoomableScrollView.swift
//  CoreMoose
//
//  Created by m x on 2023/12/5.
//

import SwiftUI
import UIKit

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    
    // MARK: Lifecycle
    
    init(contentScale: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
        self.content = content()
        _contentScale = contentScale
    }
    
    // MARK: Internal
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        
        // MARK: Lifecycle
        
        init(hostingController: UIHostingController<Content>, zoomScale: Binding<CGFloat>) {
            self.hostingController = hostingController
            _zoomScale = zoomScale
        }
        
        // MARK: Internal
        
        @Binding var zoomScale: CGFloat
        
        var hostingController: UIHostingController<Content>
        
        func viewForZooming(in _: UIScrollView) -> UIView? {
            hostingController.view
        }
        
        func scrollViewDidEndZooming(_: UIScrollView, with _: UIView?, atScale scale: CGFloat) {
            zoomScale = scale
        }
    }
    
    @Binding var contentScale: CGFloat
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5
        scrollView.minimumZoomScale = 1
//        scrollView.isScrollEnabled = false // Disable one-finger scrolling
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        
        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = true
        hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.addSubview(hostedView)
        
        return scrollView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(hostingController: UIHostingController(rootView: content), zoomScale: $contentScale)
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.hostingController.rootView = content
            // Reset the zoom scale if contentScale has been reset
            if uiView.zoomScale != contentScale {
                uiView.zoomScale = contentScale
            }
            assert(context.coordinator.hostingController.view.superview == uiView)
        }
    }
    
    // MARK: Private
    
    private var content: Content
}
