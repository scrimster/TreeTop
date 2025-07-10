//
//  FolderContentsView.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 6/29/25.
//

import SwiftUI

struct FolderContentsView: View {
    let folderURL: URL?
    @State var files: [String] = []
    @State var showCamera = false
    @State var isVieweContentsFolder = false
    @State var imagesInViewContents: [UIImage] = []
    @State var selectedImage: UIImage?
    @State var showImagePreview = false
    
    var isDiagonalFolder: Bool {
        guard let lastComponent = folderURL?.lastPathComponent else { return false }
        return lastComponent == "Diagonal 1" || lastComponent == "Diagonal 2"
    }
    
    var isViewContents: Bool {
        guard let lastComponent = folderURL?.lastPathComponent else { return false }
        return lastComponent == "View Contents"
    }
    
    var body: some View {
        return VStack {
                if isDiagonalFolder {
                    Button (action: {
                        showCamera = true
                    }) {
                        Label("Take Photo", systemImage: "camera")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                }
                
                if isViewContents {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(imagesInViewContents.indices, id: \.self) { index in
                                Image(uiImage: imagesInViewContents[index])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 200)
                                    .cornerRadius(12)
                                    .shadow(radius: 4)
                                    .onTapGesture {
                                        selectedImage = imagesInViewContents[index]
                                        showImagePreview = true
                                    }
                            }
                        }
                        .padding()
                    }
                } else {
                    List(files, id: \.self) { file in
                        let fullPath = folderURL?.appendingPathComponent(file)
                        var isDirectory: ObjCBool = false
                        
                        if let fullPath = fullPath,
                           FileManager.default.fileExists(atPath: fullPath.path, isDirectory: &isDirectory) {
                            
                            if isDirectory.boolValue {
                                NavigationLink(destination: FolderContentsView(folderURL: fullPath)) {
                                    Label(file, systemImage: "folder")
                                }
                            } else if file.lowercased().hasSuffix(".jpg") {
                                NavigationLink(destination: ImageViewerView(imageURL: fullPath)) {
                                    Label(file, systemImage: "photo")
                                }
                            } else {
                                Text(file)
                            }
                        } else {
                            Text(file)
                        }
                    }
                }
            }
            .navigationTitle("Project Contents")
               .onAppear{
                   loadFolderContents()
            }
            .navigationDestination(isPresented: $showCamera) {
                if let url = folderURL?.appendingPathComponent("View Contents") {
                    LiveCameraView(saveToURL: url)
                } else {
                    EmptyView()
                }
            }
            .sheet(isPresented: $showImagePreview) {
                if let image = selectedImage {
                    VStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding()
                        Button("Close") {
                            showImagePreview = false
                        }
                        .padding()
                    }
                }
            }
        
        func loadFolderContents() {
            guard let folderURL = folderURL else{return}
            do {
                let fileNames = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
                self.files = fileNames
                
                if isViewContents {
                    self.imagesInViewContents = fileNames
                        .filter { $0.lowercased().hasSuffix(".jpg") }
                        .compactMap { fileName in
                            let fileURL = folderURL.appendingPathComponent(fileName)
                            return UIImage(contentsOfFile: fileURL.path)}
                }
            } catch {
                print("failed to read folder: \(error)")
            }
        }
        
        struct ImageViewerView : View {
            let imageURL: URL?
            
            var body: some View {
                if let url = imageURL, let uiImage = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .navigationTitle(url.lastPathComponent)
                        .padding()
                } else {
                    Text("could not load image.")
                        .foregroundColor(.red)
                }
            }
        }
    }
}
#Preview {
    FolderContentsView(folderURL: nil)
}
