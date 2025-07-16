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
    @State var summaryResult: SummaryResult?
    @State var showSummary = false
    @State var expandedDiagonal: String? = nil
    
    var isDiagonalFolder: Bool {
        guard let lastComponent = folderURL?.lastPathComponent else { return false }
        return lastComponent == "Diagonal 1" || lastComponent == "Diagonal 2"
    }
    
    var isViewContents: Bool {
        guard let lastComponent = folderURL?.lastPathComponent else { return false }
        return lastComponent == "View Contents"
    }

    var isPhotosFolder: Bool {
        folderURL?.lastPathComponent == "Photos"
    }

    var isMasksFolder: Bool {
        folderURL?.lastPathComponent == "Masks"
    }

    var isImageFolder: Bool { isPhotosFolder || isMasksFolder }

    var isProjectFolder: Bool {
        !(isDiagonalFolder || isViewContents || isImageFolder)
    }
    
    var body: some View {
        return VStack {
            if isProjectFolder {
                Button(action: {
                    if let url = folderURL {
                        summaryResult = SummaryGenerator.createSummary(forProjectAt: url)
                        showSummary = true
                    }
                }) {
                    Label("Create Summary", systemImage: "chart.bar")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
            }
            
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
            
            if isImageFolder {
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
            }
            
            if isProjectFolder {
                VStack(spacing: 0) {
                    ForEach(files, id: \.self) { file in
                        let fullPath = folderURL?.appendingPathComponent(file)
                        var isDirectory: ObjCBool = false
                        
                        if let fullPath = fullPath,
                           FileManager.default.fileExists(atPath: fullPath.path, isDirectory: &isDirectory), isDirectory.boolValue {
                            VStack(alignment: .leading, spacing:0){
                                Button(action: {
                                    withAnimation {
                                        if expandedDiagonal == file {
                                            expandedDiagonal = nil
                                        } else {
                                            expandedDiagonal = file
                                        }
                                    }
                                }) {
                                    Label(file, systemImage: "folder")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding()
                                        .background(Color(.secondarySystemBackground))
                                }
                                
                                if expandedDiagonal == file {
                                    DiagonalContentsView(folderName: file, baseURL: folderURL!)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }
                    }
                }
            }
        }
            .navigationTitle("Project Contents")
               .onAppear{
                   loadFolderContents()
            }
            .navigationDestination(isPresented: $showCamera) {
                if let url = folderURL?.appendingPathComponent("Photos") {
                    LiveCameraView(saveToURL: url)
                } else {
                    EmptyView()
                }
            }
            .navigationDestination(isPresented: $showSummary) {
                if let result = summaryResult {
                    SummaryView(result: result)
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
                
                if isImageFolder {
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

struct DiagonalContentsView: View {
    let folderName: String
    let baseURL: URL
    
    @State private var showCamera = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                showCamera = true
            }) {
                Label("Take Photo", systemImage: "camera")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            
            NavigationLink(
                destination: FolderContentsView(folderURL: baseURL.appendingPathComponent(folderName).appendingPathComponent("Photos")
                                               )
            ) {
                Label("View Photos", systemImage: "folder")
                    .padding(.horizontal)
            }
            
            NavigationLink(
                destination: FolderContentsView(
                    folderURL: baseURL
                        .appendingPathComponent(folderName)
                        .appendingPathComponent("Masks"))
            ) {
                Label("View Masks", systemImage: "folder")
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .sheet(isPresented: $showCamera) {
            let saveURL = baseURL.appendingPathComponent(folderName)
                .appendingPathComponent("Photos")
            LiveCameraView(saveToURL: saveURL)
        }
    }
}

#Preview {
    FolderContentsView(folderURL: nil)
}
