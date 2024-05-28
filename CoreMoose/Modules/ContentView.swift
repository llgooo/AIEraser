//
//  ContentView.swift
//  CoreMoose
//
//  Created by m x on 2023/12/4.
//

import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var navigationStore: NavigationStore
    
    @State private var selectedIndex = 0
    @State private var isTouchingTabImage = false
    
    @State private var presentPicker = false
    
    private let images = ["p1", "p2", "ai1", "ai2"]
    
    private var timerPublisher: AnyPublisher<Date, Never> {
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .pause(if: isTouchingTabImage)
            .eraseToAnyPublisher()
    }
    
    var body: some View {
        GeometryReader { geo in
            NavigationStack(path: $navigationStore.paths) {
                VStack {
                    TabView(selection: $selectedIndex) {
                        ForEach(0..<images.count, id: \.self) { index in
                            Image(images[index])
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .tag(index)
                                .onTapGesture {
                                    navigationStore.navigateToPath(.editPhoto(UIImage(named: images[index])!.pngData()!))
                                }
                                .gesture(DragGesture(minimumDistance: 0)
                                    .onChanged { _ in
                                        isTouchingTabImage = true
                                    }
                                    .onEnded { _ in
                                        isTouchingTabImage = false
                                    }
                                )
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(width: geo.size.width - 20, height: geo.size.height - (geo.size.width / 3) - 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onReceive(timerPublisher) { _ in
                        withAnimation(.easeInOut(duration: 1)) {
                            selectedIndex = (selectedIndex + 1) % images.count
                        }
                    }
                    
                    HStack {
                        PhotoPickerView(systemImage: "eraser", name: "Cleanup".localized) { imageData in
                            navigationStore.navigateToPath(.editPhoto(imageData))
                        }
                        .frame(width: (geo.size.width - 30) / 2, height: (geo.size.width / 3))
                        .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        
                        PhotoPickerView(systemImage: "magnifyingglass", name: "Upscaler".localized) { imageData in
                            navigationStore.navigateToPath(.upscalePhoto(imageData))
                        }
                        .frame(width: (geo.size.width - 30) / 2, height: (geo.size.width / 3))
                        .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .padding(.horizontal, 20)
                }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                        case .editPhoto(let photoData):
                            EditView(photoData: photoData)
                        case .upscalePhoto(let photoData):
                            UpscalerView(photoData: photoData)
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            presentPicker = true
                        } label: {
                            Image(systemName: "folder")
                        }
                        .sheet(isPresented: $presentPicker) {
                            DocumentPicker { url in
                                if let imageData = try? Data(contentsOf: url),
                                   let image  = UIImage(data: imageData)?.fixedOrientation(),
                                   let orientedImageData = image.pngData(){
                                    
                                    navigationStore.navigateToPath(.editPhoto(orientedImageData))
                                }
                            }
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        NavigationLink(destination: SettingView()) {
                            Image(systemName: "gear")
                        }
                    }
                }
                .navigationTitle("AI Eraser")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarTitleDisplayMode(.large)
                
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NavigationStore())
        .tint(.primary)
}
