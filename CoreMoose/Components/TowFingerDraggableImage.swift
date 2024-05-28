//
//  TowFingerDraggableImage.swift
//  CoreMoose
//
//  Created by m x on 2023/12/28.
//

import SwiftUI
import UIKit

struct TwoFingerDraggableImage: UIViewRepresentable {
    var image: UIImage
    @Binding var offset: CGSize

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView(image: image)
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit

        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePanGesture(_:)))
        panGesture.minimumNumberOfTouches = 2
        imageView.addGestureRecognizer(panGesture)

        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.transform = CGAffineTransform(translationX: offset.width, y: offset.height)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: TwoFingerDraggableImage

        init(_ parent: TwoFingerDraggableImage) {
            self.parent = parent
        }

        @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)
            parent.offset = CGSize(width: translation.x, height: translation.y)
        }
    }
}
