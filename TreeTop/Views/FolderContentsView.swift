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
                                
                                // Check if project has any photos before starting analysis using existing property
                                if let project = project, project.needsPhotos {
                                    print("⚠️ Analysis cancelled: No photos found in project")
                                    return
                                }
                                
                                // Delete all existing masks before starting new analysis
                                deleteAllMasks(projectURL: url)
                                
                                isGeneratingSummary = true
                                summaryProgress = (current: 0, total: 0)
                                summaryProgressMessage = "Cleaning old masks and initializing..."
                                
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
                                .background(
                                    isGeneratingSummary ? Color.gray : 
                                    (project?.needsPhotos == true ? Color.gray.opacity(0.5) : Color.blue.opacity(0.8))
                                )
                                .glassText()
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                            .disabled(isGeneratingSummary || project?.needsPhotos == true)
                            
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
                            
                            // Visual Diagonal Selector
                            DiagonalVisualizerView(
                                project: project,
                                folderURL: folderURL,
                                selectedDiagonal: $selectedDiagonal,
                                showCamera: $showCamera
                            )
                            .padding(.horizontal)
                            
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
                                                if file == "Center Reference" {
                                                    CenterReferenceView(folderName: file, baseURL: folderURL!, project: project)
                                                        .transition(.asymmetric(
                                                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                                            removal: .opacity.combined(with: .scale(scale: 0.95))
                                                        ))
                                                } else {
                                                    DiagonalContentsView(folderName: file, baseURL: folderURL!, project: project)
                                                        .transition(.asymmetric(
                                                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                                            removal: .opacity.combined(with: .scale(scale: 0.95))
                                                        ))
                                                }
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
                    .navigationTitle(diagonal)
                    .navigationBarTitleDisplayMode(.inline)
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
            
            // Sort files to ensure proper order (Diagonal 1 before Diagonal 2, Center Reference last)
            self.files = fileNames.sorted { (file1, file2) in
                // Special handling for diagonal folders to ensure correct order
                if file1 == "Diagonal 1" && file2 == "Diagonal 2" {
                    return true  // Diagonal 1 comes before Diagonal 2
                } else if file1 == "Diagonal 2" && file2 == "Diagonal 1" {
                    return false // Diagonal 2 comes after Diagonal 1
                } else if file1 == "Center Reference" {
                    return false // Center Reference comes last
                } else if file2 == "Center Reference" {
                    return true  // Anything else comes before Center Reference
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
    
    private func deleteAllMasks(projectURL: URL) {
        let fileManager = FileManager.default
        
        // Delete masks from Diagonal 1
        let diagonal1MasksURL = projectURL.appendingPathComponent("Diagonal 1").appendingPathComponent("Masks")
        deleteMasksInDirectory(url: diagonal1MasksURL, fileManager: fileManager)
        
        // Delete masks from Diagonal 2
        let diagonal2MasksURL = projectURL.appendingPathComponent("Diagonal 2").appendingPathComponent("Masks")
        deleteMasksInDirectory(url: diagonal2MasksURL, fileManager: fileManager)
        
        print("✅ All existing masks deleted for fresh analysis")
    }
    
    private func deleteMasksInDirectory(url: URL, fileManager: FileManager) {
        guard fileManager.fileExists(atPath: url.path) else { return }
        
        do {
            let maskFiles = try fileManager.contentsOfDirectory(atPath: url.path)
            
            for maskFile in maskFiles {
                let maskFileURL = url.appendingPathComponent(maskFile)
                
                // Only delete image files (masks)
                if maskFile.lowercased().hasSuffix(".png") || 
                   maskFile.lowercased().hasSuffix(".jpg") || 
                   maskFile.lowercased().hasSuffix(".jpeg") {
                    try fileManager.removeItem(at: maskFileURL)
                    print("🗑️ Deleted mask: \(maskFile)")
                }
            }
        } catch {
            print("⚠️ Error deleting masks in \(url.path): \(error)")
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
    let project: Project?
    
    @State private var showCamera = false
    @State private var images: [URL] = []
    @State private var showDeleteAlert = false
    @State private var imageToDelete: URL? = nil
    @State private var showDeleteAllAlert = false

    var photosURL: URL {
        baseURL.appendingPathComponent(folderName).appendingPathComponent("Photos")
    }

    var body: some View {
        LiquidGlassCard(cornerRadius: 12) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Photos")
                        .font(.headline)
                        .glassText()
                    Spacer()
                    if !images.isEmpty {
                        Button(role: .destructive) {
                            showDeleteAllAlert = true
                        } label: {
                            Label("Delete All", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                        .alert("Delete all photos?", isPresented: $showDeleteAllAlert) {
                            Button("Delete All", role: .destructive) { deleteAllImages() }
                            Button("Cancel", role: .cancel) { }
                        } message: {
                            Text("This will permanently delete all photos in this diagonal.")
                        }
                    }
                }
                
                if images.isEmpty {
                    Text("No photos found.")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(images, id: \.self) { url in
                                VStack(spacing: 4) {
                                    if let img = UIImage(contentsOfFile: url.path) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 120, height: 120)
                                            .cornerRadius(10)
                                            .shadow(radius: 2)
                                    }
                                    Button(role: .destructive) {
                                        imageToDelete = url
                                        showDeleteAlert = true
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .alert("Delete this photo?", isPresented: Binding(
                                        get: { imageToDelete == url && showDeleteAlert },
                                        set: { _ in showDeleteAlert = false }
                                    )) {
                                        Button("Delete", role: .destructive) { deleteImage(url) }
                                        Button("Cancel", role: .cancel) { }
                                    } message: {
                                        Text("This will permanently delete the selected photo.")
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                NavigationLink(
                    destination: FolderContentsView(
                        folderURL: baseURL.appendingPathComponent(folderName).appendingPathComponent("Masks"),
                        project: project
                    )
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
            .onAppear(perform: loadImages)
        }
        .sheet(isPresented: $showCamera) {
            NavigationView {
                LiveCameraView(saveToURL: photosURL)
                    .navigationTitle("\(folderName) Photos")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Done") {
                                showCamera = false
                            }
                        }
                    }
            }
        }
    }

    private func loadImages() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: photosURL.path) else { images = []; return }
        do {
            let files = try fm.contentsOfDirectory(atPath: photosURL.path)
            images = files.filter { fileName in
                fileName.lowercased().hasSuffix(".jpg") || 
                fileName.lowercased().hasSuffix(".jpeg") || 
                fileName.lowercased().hasSuffix(".png")
            }.map { photosURL.appendingPathComponent($0) }
        } catch {
            images = []
        }
    }

    private func deleteImage(_ url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            loadImages()
        } catch {
            print("Error deleting image: \(error)")
        }
    }

    private func deleteAllImages() {
        for url in images {
            try? FileManager.default.removeItem(at: url)
        }
        loadImages()
    }
}

struct CenterReferenceView: View {
    let folderName: String
    let baseURL: URL
    let project: Project?
    
    @State private var showCamera = false
    
    var body: some View {
        LiquidGlassCard(cornerRadius: 12) {
            VStack(alignment: .leading, spacing: 8) {
                NavigationLink(
                    destination: FolderContentsView(
                        folderURL: baseURL.appendingPathComponent(folderName),
                        project: project
                    )
                ) {
                    HStack {
                        Image(systemName: "camera.macro.circle")
                            .foregroundColor(.orange.opacity(0.85))
                            .font(.system(size: 16))
                        
                        Text("View Reference Images")
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
                
                Button(action: {
                    showCamera = true
                }) {
                    HStack {
                        Image(systemName: "camera.badge.ellipsis")
                            .foregroundColor(.orange.opacity(0.85))
                            .font(.system(size: 16))
                        
                        Text("Take Reference Photo")
                            .foregroundColor(.white.opacity(0.95))
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                        
                        Spacer()
                        
                        Image(systemName: "plus.circle")
                            .foregroundColor(.orange.opacity(0.5))
                            .font(.system(size: 12, weight: .semibold))
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
            NavigationView {
                LiveCameraView(saveToURL: saveURL)
                    .navigationTitle("Center Reference")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Done") {
                                showCamera = false
                            }
                        }
                    }
            }
        }
    }
}

struct DiagonalVisualizerView: View {
    let project: Project?
    let folderURL: URL?
    @Binding var selectedDiagonal: String?
    @Binding var showCamera: Bool
    
    @State private var showCenterCamera = false
    
    var body: some View {
        LiquidGlassCard(cornerRadius: 16) {
            VStack(spacing: 16) {
                Text("Photo Capture Areas")
                    .font(.headline)
                    .glassText()
                
                ZStack {
                    // Background circle
                    Circle()
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 200, height: 200)
                    
                    // Diagonal 1 (Top-left to bottom-right) - Blue
                    Path { path in
                        path.move(to: CGPoint(x: 50, y: 50))
                        path.addLine(to: CGPoint(x: 150, y: 150))
                    }
                    .stroke(Color.blue, lineWidth: 8)
                    .frame(width: 200, height: 200)
                    
                    // Diagonal 2 (Top-right to bottom-left) - Green  
                    Path { path in
                        path.move(to: CGPoint(x: 150, y: 50))
                        path.addLine(to: CGPoint(x: 50, y: 150))
                    }
                    .stroke(Color.green, lineWidth: 8)
                    .frame(width: 200, height: 200)
                    
                    // Center reference point - Orange
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                    
                    // Invisible tap areas
                    // Diagonal 1 tap area (blue) - Top-left to bottom-right
                    Path { path in
                        path.move(to: CGPoint(x: 40, y: 40))
                        path.addLine(to: CGPoint(x: 160, y: 40))
                        path.addLine(to: CGPoint(x: 160, y: 160))
                        path.addLine(to: CGPoint(x: 100, y: 160))
                        path.addLine(to: CGPoint(x: 40, y: 100))
                        path.closeSubpath()
                    }
                    .fill(Color.blue.opacity(0.001))
                    .frame(width: 200, height: 200)
                    .onTapGesture {
                        selectedDiagonal = "Diagonal 1"
                        showCamera = true
                    }
                    
                    // Diagonal 2 tap area (green) - Top-right to bottom-left
                    Path { path in
                        path.move(to: CGPoint(x: 40, y: 40))
                        path.addLine(to: CGPoint(x: 160, y: 40))
                        path.addLine(to: CGPoint(x: 160, y: 100))
                        path.addLine(to: CGPoint(x: 100, y: 160))
                        path.addLine(to: CGPoint(x: 40, y: 160))
                        path.closeSubpath()
                    }
                    .fill(Color.green.opacity(0.001))
                    .frame(width: 200, height: 200)
                    .onTapGesture {
                        selectedDiagonal = "Diagonal 2"
                        showCamera = true
                    }
                    
                    // Center tap area (orange)
                    Circle()
                        .fill(Color.orange.opacity(0.001))
                        .frame(width: 40, height: 40)
                        .onTapGesture {
                            showCenterCamera = true
                        }
                }
                
                // Legend
                HStack(spacing: 20) {
                    // Diagonal 1 legend
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 20, height: 4)
                        Text("Diagonal 1")
                            .font(.caption)
                            .glassTextSecondary()
                    }
                    
                    // Diagonal 2 legend
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: 20, height: 4)
                        Text("Diagonal 2")
                            .font(.caption)
                            .glassTextSecondary()
                    }
                    
                    // Center reference legend
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 12, height: 12)
                        Text("Center Reference")
                            .font(.caption)
                            .glassTextSecondary()
                    }
                }
                
                Text("Tap on a diagonal line or center point to take photos")
                    .font(.caption2)
                    .glassTextSecondary()
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        }
        .sheet(isPresented: $showCenterCamera) {
            if let folderURL = folderURL {
                let centerURL = folderURL.appendingPathComponent("Center Reference")
                LiveCameraView(saveToURL: centerURL)
            }
        }
    }
}
