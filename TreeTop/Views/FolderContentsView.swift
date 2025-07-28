//
//  FolderContentsView.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 6/29/25.
//

import SwiftUI
import SwiftData

struct FolderContentsView: View {
    let folderURL: URL?
    let project: Project? // Optional project for getting the real name
    @Environment(\.modelContext) private var modelContext
    @State var files: [String] = []
    @State var showCamera = false
    @State var isVieweContentsFolder = false
    @State var imagesInViewContents: [UIImage] = []
    @State var selectedImage: UIImage?
    @State var showImagePreview = false
    @State var summaryResult: SummaryResult?
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

    var isImageFolder: Bool { 
        isPhotosFolder || isMasksFolder 
    }
    
    var isProjectFolder: Bool {
        guard let folderURL = folderURL else { return false }
        let folderName = folderURL.lastPathComponent
        
        // Check if the folder name contains a UUID pattern
        let uuidPattern = "[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}"
        let regex = try? NSRegularExpression(pattern: uuidPattern, options: .caseInsensitive)
        
        if let regex = regex {
            let range = NSRange(location: 0, length: folderName.utf16.count)
            return regex.firstMatch(in: folderName, options: [], range: range) != nil
        }
        
        return false
    }
    
    var projectName: String {
        // If we have a project object, use its actual name
        if let project = project {
            return project.name
        }
        
        // Fallback for when no project is provided
        guard let folderURL = folderURL else { return "Unknown Project" }
        let folderName = folderURL.lastPathComponent
        
        // UUID pattern to match and remove from the folder name (fallback only)
        // Format: "ProjectName - UUID" where UUID is 8-4-4-4-12 hex digits
        let uuidPattern = " - [0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}"
        
        do {
            let regex = try NSRegularExpression(pattern: uuidPattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: folderName.utf16.count)
            
            if let match = regex.firstMatch(in: folderName, options: [], range: range) {
                let projectPart = String(folderName.prefix(match.range.location))
                return projectPart.isEmpty ? "Project Contents" : projectPart
            }
        } catch {
            print("Regex error: \(error)")
        }
        
        // Final fallback: if regex fails or no UUID found, return the whole name
        return folderName.isEmpty ? "Project Contents" : folderName
    }
    
    var body: some View {
        ZStack {
            AnimatedForestBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isProjectFolder {
                        VStack(spacing: 12) {
                            Button(action: {
                                guard let url = folderURL, !isGeneratingSummary else { return }
                                
                                isGeneratingSummary = true
                                summaryProgress = (current: 0, total: 0)
                                summaryProgressMessage = "Initializing..."
                                
                                SummaryGenerator.createSummaryAsync(
                                    forProjectAt: url,
                                    progressCallback: { message, current, total in
                                        DispatchQueue.main.async {
                                            summaryProgress = (current: current, total: total)
                                            summaryProgressMessage = message
                                        }
                                    },
                                    completion: { result in
                                        DispatchQueue.main.async {
                                            isGeneratingSummary = false
                                            switch result {
                                            case .success(let summary):
                                                summaryResult = summary
                                                
                                                // Save results to project if available
                                                if let project = project {
                                                    // Update project with analysis results
                                                    project.canopyCoverPercentage = summary.overallAverage
                                                    project.lastAnalysisDate = Date()
                                                    
                                                    // Store diagonal results in separate properties for SwiftData compatibility
                                                    project.diagonal1Percentage = summary.diagonalAverages["Diagonal 1"]
                                                    project.diagonal2Percentage = summary.diagonalAverages["Diagonal 2"]
                                                    
                                                    // Save to persistent storage
                                                    do {
                                                        try modelContext.save()
                                                    } catch {
                                                        print("Error saving analysis results: \(error)")
                                                    }
                                                }
                                                
                                            case .failure(let error):
                                                summaryErrorMessage = error.localizedDescription
                                                showSummaryError = true
                                            }
                                        }
                                    }
                                )
                            }) {
                                HStack {
                                    if isGeneratingSummary {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "chart.bar.doc.horizontal")
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                    
                                    Text(isGeneratingSummary ? "Running Analysis..." : "Run Canopy Analysis")
                                        .font(.headline)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(isGeneratingSummary ? Color.gray : Color.blue.opacity(0.8))
                                .glassText()
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
                                        .glassTextSecondary()
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    
                                    if summaryProgress.total > 0 {
                                        Text("\(summaryProgress.current) / \(summaryProgress.total) images processed")
                                            .font(.caption2)
                                            .glassTextSecondary()
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
                            
                            // Always display expandable summary
                            ExpandableSummaryView(result: summaryResult, project: project, initiallyExpanded: false)
                                .padding(.horizontal)
                            
                            Button(action: {
                                showTakePhotoOptions = true
                            }) {
                                Label("Take Photo", systemImage: "camera")
                                    .font(.headline)
                                    .glassText()
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
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
                            
                            VStack(spacing: 12) {
                                ForEach(files, id: \.self) { file in
                                    let fullPath = folderURL?.appendingPathComponent(file)
                                    var isDirectory: ObjCBool = false
                                    
                                    if let fullPath = fullPath,
                                       FileManager.default.fileExists(atPath: fullPath.path, isDirectory: &isDirectory), isDirectory.boolValue {
                                        VStack(alignment: .leading, spacing: 8) {
                                            LiquidGlassButton(cornerRadius: 14, action: {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    if expandedDiagonal == file {
                                                        expandedDiagonal = nil
                                                    } else {
                                                        expandedDiagonal = file
                                                    }
                                                }
                                            }) {
                                                HStack {
                                                    Image(systemName: expandedDiagonal == file ? "folder.fill" : "folder")
                                                        .glassTextSecondary(opacity: 0.85)
                                                        .font(.system(size: 20))
                                                    
                                                    Text(file)
                                                        .glassText()
                                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: expandedDiagonal == file ? "chevron.down" : "chevron.right")
                                                        .glassTextSecondary(opacity: 0.6)
                                                        .font(.system(size: 12, weight: .semibold))
                                                        .animation(.easeInOut(duration: 0.2), value: expandedDiagonal == file)
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 14)
                                            }
                                            
                                            if expandedDiagonal == file {
                                                DiagonalContentsView(folderName: file, baseURL: folderURL!, project: project)
                                                    .transition(.asymmetric(
                                                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                                        removal: .opacity.combined(with: .scale(scale: 0.95))
                                                    ))
                                            }
                                        }
                                        .padding(.horizontal, 4)
                                        .id(file)
                                    }
                                }
                            }
                            .animation(.easeInOut(duration: 0.3), value: expandedDiagonal)
                        }
                    }
                    
                    if isDiagonalFolder {
                        Button(action: {
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
        }
        .navigationTitle(projectName)
        .onAppear {
            loadFolderContents()
            
            // Update project statistics to detect photo changes
            if let project = project {
                ProjectStatisticsManager.shared.updateProjectStatistics(project)
            }
            
            // Load stored analysis results if available
            if let project = project, let storedResult = project.storedSummaryResult {
                summaryResult = storedResult
            }
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
        .alert("Analysis Failed", isPresented: $showSummaryError) {
            Button("OK") { }
        } message: {
            Text(summaryErrorMessage)
        }
    }
    
    private func loadFolderContents() {
        guard let folderURL = folderURL else { return }
        do {
            let fileNames = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
            
            // Sort files to ensure proper order (Diagonal 1 before Diagonal 2, etc.)
            self.files = fileNames.sorted { (file1, file2) in
                // Special handling for diagonal folders to ensure correct order
                if file1 == "Diagonal 1" && file2 == "Diagonal 2" {
                    return true  // Diagonal 1 comes before Diagonal 2
                } else if file1 == "Diagonal 2" && file2 == "Diagonal 1" {
                    return false // Diagonal 2 comes after Diagonal 1
                }
                // For all other files, use natural string comparison
                return file1.localizedStandardCompare(file2) == .orderedAscending
            }
            
            if isImageFolder {
                self.imagesInViewContents = fileNames
                    .filter { $0.lowercased().hasSuffix(".jpg") }
                    .compactMap { fileName in
                        let fileURL = folderURL.appendingPathComponent(fileName)
                        return UIImage(contentsOfFile: fileURL.path)
                    }
            }
        } catch {
            print("failed to read folder: \(error)")
        }
    }
}

struct ImageViewerView: View {
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

struct DiagonalContentsView: View {
    let folderName: String
    let baseURL: URL
    let project: Project? // Add project parameter
    
    @State private var showCamera = false
    
    var body: some View {
        LiquidGlassCard(cornerRadius: 12) {
            VStack(alignment: .leading, spacing: 8) {
                NavigationLink(
                    destination: FolderContentsView(folderURL: baseURL.appendingPathComponent(folderName).appendingPathComponent("Photos"), project: project)
                ) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .foregroundColor(.white.opacity(0.85))
                            .font(.system(size: 16))
                        
                        Text("View Photos")
                            .foregroundColor(.white.opacity(0.95))
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .liquidGlass(cornerRadius: 8, strokeOpacity: 0.15)
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(
                    destination: FolderContentsView(
                        folderURL: baseURL
                            .appendingPathComponent(folderName)
                            .appendingPathComponent("Masks"), project: project)
                ) {
                    HStack {
                        Image(systemName: "rectangle.on.rectangle")
                            .foregroundColor(.white.opacity(0.85))
                            .font(.system(size: 16))
                        
                        Text("View Masks")
                            .foregroundColor(.white.opacity(0.95))
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .liquidGlass(cornerRadius: 8, strokeOpacity: 0.15)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(12)
        }
        .sheet(isPresented: $showCamera) {
            let saveURL = baseURL.appendingPathComponent(folderName)
                .appendingPathComponent("Photos")
            LiveCameraView(saveToURL: saveURL)
        }
    }
}

#Preview {
    FolderContentsView(folderURL: nil, project: nil)
}
