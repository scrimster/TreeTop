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
    @State var showTakePhotoOptions = false
    @State var selectedDiagonal: String? = nil
    
    // AI analysis state management
    @State private var isGeneratingSummary = false
    @State private var summaryProgress: (current: Int, total: Int) = (0, 0)
    @State private var summaryProgressMessage = ""
    @State private var showSummaryError = false
    @State private var summaryErrorMessage = ""
    
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
        ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            if isProjectFolder {
                VStack(spacing: 12) {
                    Button(action: {
                        guard let url = folderURL, !isGeneratingSummary else { return }
                        
                        isGeneratingSummary = true
                        summaryProgress = (0, 0)
                        summaryProgressMessage = "Initializing..."
                        
                        SummaryGenerator.createSummaryAsync(
                            forProjectAt: url,
                            progressCallback: { message, current, total in
                                summaryProgressMessage = message
                                summaryProgress = (current, total)
                            },
                            completion: { result in
                                isGeneratingSummary = false
                                
                                switch result {
                                case .success(let summary):
                                    summaryResult = summary
                                    showSummary = true
                                    print("✅ Summary generation completed successfully")
                                    
                                case .failure(let error):
                                    summaryErrorMessage = error.localizedDescription
                                    showSummaryError = true
                                    print("❌ Summary generation failed: \(error)")
                                }
                            }
                        )
                    }) {
                        HStack {
                            if isGeneratingSummary {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                                Text("Analyzing...")
                            } else {
                                Label("Create Summary", systemImage: "chart.bar")
                            }
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isGeneratingSummary ? Color.gray : Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .disabled(isGeneratingSummary)
                    
                    // Progress indicator for AI analysis
                    if isGeneratingSummary {
                        VStack(spacing: 8) {
                            ProgressView(value: Double(summaryProgress.current), total: Double(max(1, summaryProgress.total)))
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                .padding(.horizontal)
                            
                            Text(summaryProgressMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            if summaryProgress.total > 0 {
                                Text("\(summaryProgress.current) / \(summaryProgress.total) images processed")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button("Cancel Analysis") {
                                isGeneratingSummary = false
                                SummaryGenerator.cancelSummaryGeneration()
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    
                    Button(action: {
                        showTakePhotoOptions = true
                    }) {
                        Label("Take Photo", systemImage: "camera")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    .confirmationDialog("Choose Diagonal", isPresented: $showTakePhotoOptions, titleVisibility: .visible) {
                        Button("Diagonal 1") {
                            selectedDiagonal = "Diagonal 1"
                            showCamera = true
                        }
                        Button("Diagonal 2") {
                            selectedDiagonal = "Diagonal 2"
                            showCamera = true
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                    
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
                                            .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                                    }
                                }
                                .id(file)
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: expandedDiagonal)
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
        }
    }
            .navigationTitle("Project Contents")
               .onAppear{
                   loadFolderContents()
               }
            .navigationDestination(isPresented: $showCamera) {
               if let diagonal = selectedDiagonal,
                  let folder = folderURL?
                .appendingPathComponent(diagonal)
                .appendingPathComponent("Photos") {
                   LiveCameraView(saveToURL: folder)
               } else {
                   EmptyView()
               }
           }
    //            .navigationDestination(isPresented: $showCamera) {
    //                if let url = folderURL?.appendingPathComponent("Photos") {
    //                    LiveCameraView(saveToURL: url)
    //                } else {
    //                    EmptyView()
    //                }
    //            }
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
            .alert("Summary Generation Failed", isPresented: $showSummaryError) {
                Button("OK") { }
            } message: {
                Text(summaryErrorMessage)
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

struct DiagonalContentsView: View {
    let folderName: String
    let baseURL: URL
    
    @State private var showCamera = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
//            Button(action: {
//                showCamera = true
//            }) {
//                Label("Take Photo", systemImage: "camera")
//                    .font(.headline)
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color.green)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//                    .padding(.horizontal)
//            }
//            .transaction { $0.disablesAnimations = true }
            
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
