//
//  PhotoPickerView.swift
//  CoreMoose
//
//  Created by m x on 2024/2/5.
//

import PhotosUI
import SwiftUI

struct PhotoPickerView: View {
    var systemImage: String
    var name: String
    var onPhotoSelected: (Data) -> Void
    
    @State private var selectItem: PhotosPickerItem?
    
    var body: some View {
        VStack {
            PhotosPicker(selection: $selectItem, matching: .images, photoLibrary: .shared()) {
                VStack {
                    Image(systemName: systemImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                    Text(name)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 10)
                }
            }
            .onChange(of: selectItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image  = UIImage(data: data)?.fixedOrientation(),
                       let orientedImageData = image.pngData() {
                        onPhotoSelected(orientedImageData)
                    }
                    selectItem = nil
                }
            }
        }
    }
}
