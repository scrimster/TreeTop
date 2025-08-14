//
//  FolderContentsView.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 6/29/25.
//
//  REFACTORED - Large components have been extracted into separate files:
//  - ProjectDataCard.swift
//  - DiagonalFolderView.swift
//  - ImageGalleryView.swift
//  - AnalysisControlsView.swift
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

    // PDF export state
    @State private var isExportingPDF = false
    @State private var exportedPDFURL: URL? = nil
    @State private var showShareSheet = false
    @State private var exportErrorMessage = ""
    @State private var showExportError = false
    
    // Tab selection: Overview vs Capture
    private enum ProjectTab: String, CaseIterable, Identifiable { case overview = "Overview", capture = "Capture"; var id: String { rawValue } }
    @State private var selectedTab: ProjectTab = .overview

    // Capture counts for compact cards
    @State private var d1PhotosCount: Int = 0
    @State private var d1MasksCount: Int = 0
    @State private var d2PhotosCount: Int = 0
    @State private var d2MasksCount: Int = 0
    @State private var showAdvancedFolders: Bool = false
    @State private var showClearDiagonalAlert: Bool = false
    @State private var diagonalToClear: String? = nil
    
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
            // Regex error occurred during processing
        }
        
        // Final fallback: if regex fails or no UUID found, return the whole name
        return folderName.isEmpty ? "Project Contents" : folderName
    }
    
    var body: some View {
        ZStack {
            // Simplified static background to reduce Metal rendering load
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.15, blue: 0.4),
                    Color(red: 0.12, green: 0.4, blue: 0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isProjectFolder {
                        VStack(spacing: 14) {
                            // Tab selector
                            Picker("Tab", selection: $selectedTab) {
                                Text(ProjectTab.overview.rawValue).tag(ProjectTab.overview)
                                Text(ProjectTab.capture.rawValue).tag(ProjectTab.capture)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)

                            switch selectedTab {
                            case .overview:
                                // 1) Project details first
                                if let project = project {
                                    ProjectDataCard(project: project)
                                        .padding(.horizontal)
                                }

                                // 2) Analysis summary
                                ExpandableSummaryView(result: summaryResult, project: project, initiallyExpanded: false)
                                    .padding(.horizontal)


                                // 3) Analysis Controls
                                AnalysisControlsView(
                                    project: project,
                                    folderURL: folderURL,
                                    onAnalysisComplete: { summary in
                                        summaryResult = summary
                                        if let project = project {
                                            project.canopyCoverPercentage = summary.overallAverage
                                            project.lastAnalysisDate = Date()
                                            project.diagonal1Percentage = summary.diagonalAverages["Diagonal 1"]
                                            project.diagonal2Percentage = summary.diagonalAverages["Diagonal 2"]
                                            try? modelContext.save()
                                        }
                                    },
                                    onAnalysisError: { error in
                                        summaryErrorMessage = error
                                        showSummaryError = true
                                    }
                                )
                                .padding(.horizontal)

                                Spacer(minLength: 8)

                            case .capture:
                                if let project = project {
                                    CenterReferenceProjectSection(project: project)
                                        .padding(.horizontal)
                                }

                                // Compact visual guide
                                DiagonalVisualizerView(
                                    project: project,
                                    folderURL: folderURL,
                                    selectedDiagonal: $selectedDiagonal,
                                    showCamera: $showCamera
                                )
                                .padding(.horizontal)

                                // Removed diagonal photos buttons by request

                                // Advanced folders (optional)
                                DisclosureGroup(isExpanded: $showAdvancedFolders) {
                                    VStack(spacing: 12) {
                                        ForEach(files, id: \.self) { file in
                                            let fullPath = folderURL?.appendingPathComponent(file)
                                            var isDirectory: ObjCBool = false
                                            if let fullPath = fullPath,
                                               FileManager.default.fileExists(atPath: fullPath.path, isDirectory: &isDirectory), isDirectory.boolValue {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    LiquidGlassButton(cornerRadius: 14, action: {
                                                        withAnimation(.easeInOut(duration: 0.3)) { expandedDiagonal = (expandedDiagonal == file) ? nil : file }
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
                                                        }
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 14)
                                                    }
                                                    if expandedDiagonal == file {
                                                        DiagonalContentsView(folderName: file, baseURL: folderURL!, project: project)
                                                            .transition(.opacity)
                                                    }
                                                }
                                                .padding(.horizontal, 4)
                                                .id(file)
                                            }
                                        }
                                    }
                                    .animation(.easeInOut(duration: 0.3), value: expandedDiagonal)
                                } label: {
                                    Text(showAdvancedFolders ? "Hide advanced folders" : "Show advanced folders")
                                        .font(.system(.footnote, design: .rounded))
                                        .glassTextSecondary()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 6)
                                }
                                .padding(.horizontal)
                            }
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
                        ImageGalleryView(
                            images: imagesInViewContents,
                            onDelete: { index in
                                // Handle image deletion
                                if index < imagesInViewContents.count {
                                    // Remove from array and file system
                                    let imageToDelete = imagesInViewContents[index]
                                    imagesInViewContents.remove(at: index)
                                    // TODO: Delete from file system
                                }
                            },
                            onImageTap: { image in
                                selectedImage = image
                                showImagePreview = true
                            }
                        )
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
                    .appendingPathComponent("Photos"),
               let project = project {
                
                LiveCameraView(saveToURL: folder, project: project, diagonalName: diagonal)
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
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedPDFURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("Analysis Failed", isPresented: $showSummaryError) {
            Button("OK") { }
        } message: {
            Text(summaryErrorMessage)
        }
        .alert("Export Failed", isPresented: $showExportError) {
            Button("OK") { }
        } message: {
            Text(exportErrorMessage)
        }
        .alert(isPresented: $showClearDiagonalAlert) {
            Alert(
                title: Text("Clear Diagonal"),
                message: Text("This will permanently delete all Photos and Masks in \(diagonalToClear ?? "this diagonal")."),
                primaryButton: .destructive(Text("Clear")) {
                    if let diag = diagonalToClear, let base = folderURL {
                        clearDiagonal(named: diag, at: base)
                        loadFolderContents()
                    }
                },
                secondaryButton: .cancel { diagonalToClear = nil }
            )
        }
    }
    
    private func loadFolderContents() {
        guard let folderURL = folderURL else { return }
        do {
            let fileNames = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
            
            // Filter out Center Reference folder - it will be handled directly in project details
            let filteredFiles = fileNames.filter { $0 != "Center Reference" }
            
            // Sort files to ensure proper order (Diagonal 1 before Diagonal 2)
            self.files = filteredFiles.sorted { (file1, file2) in
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
            // Update compact capture counts
            let d1PhotosURL = folderURL.appendingPathComponent("Diagonal 1").appendingPathComponent("Photos")
            let d1MasksURL = folderURL.appendingPathComponent("Diagonal 1").appendingPathComponent("Masks")
            let d2PhotosURL = folderURL.appendingPathComponent("Diagonal 2").appendingPathComponent("Photos")
            let d2MasksURL = folderURL.appendingPathComponent("Diagonal 2").appendingPathComponent("Masks")
            let fm = FileManager.default
            d1PhotosCount = (try? fm.contentsOfDirectory(atPath: d1PhotosURL.path).filter { $0.lowercased().hasSuffix(".jpg") }.count) ?? 0
            d1MasksCount  = (try? fm.contentsOfDirectory(atPath: d1MasksURL.path).filter { $0.lowercased().hasSuffix(".jpg") || $0.lowercased().hasSuffix(".png") || $0.lowercased().hasSuffix(".jpeg") }.count) ?? 0
            d2PhotosCount = (try? fm.contentsOfDirectory(atPath: d2PhotosURL.path).filter { $0.lowercased().hasSuffix(".jpg") }.count) ?? 0
            d2MasksCount  = (try? fm.contentsOfDirectory(atPath: d2MasksURL.path).filter { $0.lowercased().hasSuffix(".jpg") || $0.lowercased().hasSuffix(".png") || $0.lowercased().hasSuffix(".jpeg") }.count) ?? 0
        } catch {
            // Failed to read folder contents
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
        
                    // All existing masks deleted for fresh analysis
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
                                            // Deleted mask file
                }
            }
        } catch {
                            // Error deleting masks in directory
        }
    }

    private func clearDiagonal(named name: String, at base: URL) {
        let fm = FileManager.default
        let photos = base.appendingPathComponent(name).appendingPathComponent("Photos")
        let masks = base.appendingPathComponent(name).appendingPathComponent("Masks")
        // Remove files inside Photos and Masks
        for dir in [photos, masks] {
            if let items = try? fm.contentsOfDirectory(atPath: dir.path) {
                for item in items {
                    let url = dir.appendingPathComponent(item)
                    try? fm.removeItem(at: url)
                }
            }
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
                            Spacer(minLength: 0)
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
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity)
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
            if let project = project {
                NavigationView {
                    LiveCameraView(saveToURL: photosURL, project: project, diagonalName: folderName)
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
            } else {
                Text("Missing project information.")
            }
        }
//        .sheet(isPresented: $showCamera) {
//            NavigationView {
//                LiveCameraView(saveToURL: photosURL, project: project, diagonalName: folderName)
//                    .navigationTitle("\(folderName) Photos")
//                    .navigationBarTitleDisplayMode(.inline)
//                    .navigationBarBackButtonHidden(true)
//                    .toolbar {
//                        ToolbarItem(placement: .navigationBarLeading) {
//                            Button("Done") {
//                                showCamera = false
//                            }
//                        }
//                    }
//            }
//        }
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
            // Error deleting image
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
                // Show center reference details if it exists
                if let project = project, project.hasCenterReference {
                    NavigationLink(destination: CenterReferenceDetailView(project: project)) {
                        HStack {
                            CenterReferenceThumbnail(project: project)
                                .frame(width: 50, height: 50)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("View Center Reference")
                                    .foregroundColor(.white.opacity(0.95))
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                
                                if let date = project.centerImageDate {
                                    Text("Captured \(date.formatted(date: .abbreviated, time: .shortened))")
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.system(size: 12, design: .rounded))
                                }
                                
                                if project.centerImageLatitude != nil {
                                    Text("📍 Location tagged")
                                        .foregroundColor(.green.opacity(0.8))
                                        .font(.system(size: 11, design: .rounded))
                                }
                            }
                            
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
                
                Button(action: {
                    showCamera = true
                }) {
                    HStack {
                        Image(systemName: project?.hasCenterReference == true ? "camera.badge.ellipsis" : "camera.macro.circle")
                            .foregroundColor(.orange.opacity(0.85))
                            .font(.system(size: 16))
                        
                        Text(project?.hasCenterReference == true ? "Replace Center Reference" : "Capture Center Reference")
                            .foregroundColor(.white.opacity(0.95))
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                        
                        Spacer()
                        
                        Image(systemName: project?.hasCenterReference == true ? "arrow.triangle.2.circlepath" : "plus.circle")
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
            if let project = project {
                NavigationView {
                    CenterReferenceCameraView(project: project)
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
}

struct DiagonalVisualizerView: View {
    let project: Project?
    let folderURL: URL?
    @Binding var selectedDiagonal: String?
    @Binding var showCamera: Bool
    
    @State private var showCenterCamera = false
    @State private var d1Complete: Bool = false
    @State private var d2Complete: Bool = false
    @State private var centerComplete: Bool = false
    @State private var showD1Options: Bool = false
    @State private var showD2Options: Bool = false
    
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
                }
                
                // Legend (center button on its own row to avoid overflow)
                VStack(spacing: 8) {
                    HStack(spacing: 20) {
                        // Diagonal 1 capture button in legend
                    Button {
                        if d1Complete {
                            showD1Options = true
                        } else {
                            selectedDiagonal = "Diagonal 1"
                            showCamera = true
                        }
                        } label: {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 20, height: 4)
                            Text(d1Complete ? "D1 Complete" : "Capture D1")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundColor(.white.opacity(0.95))
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                                .allowsTightening(true)
                                .truncationMode(.tail)
                            if d1Complete {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(d1Complete ? Color.white.opacity(0.15) : Color.blue.opacity(0.25))
                        )
                        .fixedSize(horizontal: true, vertical: false)
                        }
                        .buttonStyle(.plain)
                        
                        // Diagonal 2 capture button in legend
                    Button {
                        if d2Complete {
                            showD2Options = true
                        } else {
                            selectedDiagonal = "Diagonal 2"
                            showCamera = true
                        }
                        } label: {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: 20, height: 4)
                            Text(d2Complete ? "D2 Complete" : "Capture D2")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundColor(.white.opacity(0.95))
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                                .allowsTightening(true)
                                .truncationMode(.tail)
                            if d2Complete {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(d2Complete ? Color.white.opacity(0.15) : Color.green.opacity(0.25))
                        )
                        .fixedSize(horizontal: true, vertical: false)
                        }
                        .buttonStyle(.plain)
                    }

                    // Center reference legend as capture button (full row, centered)
                    HStack {
                        Spacer()
                        Button {
                        showCenterCamera = true
                        } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 12, height: 12)
                            Text(centerComplete ? "Center Captured" : "Capture Center")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundColor(.white.opacity(0.95))
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                                .allowsTightening(true)
                                .truncationMode(.tail)
                            if centerComplete {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(centerComplete ? Color.white.opacity(0.15) : Color.orange.opacity(0.25))
                        )
                        .fixedSize(horizontal: true, vertical: false)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                }
                
                Text("Use the legend buttons to capture along each diagonal")
                    .font(.caption2)
                    .glassTextSecondary()
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        }
        .confirmationDialog("Diagonal 1", isPresented: $showD1Options, titleVisibility: .visible) {
            Button("Add Photos") {
                selectedDiagonal = "Diagonal 1"; showCamera = true
            }
            Button("Wipe Photos & Masks", role: .destructive) {
                if let base = folderURL { clearDiagonal(named: "Diagonal 1", at: base) }
                refreshCompletionStates()
                NotificationCenter.default.post(name: .diagonalPhotosSaved, object: nil, userInfo: ["diagonal": "Diagonal 1"]) 
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Diagonal 2", isPresented: $showD2Options, titleVisibility: .visible) {
            Button("Add Photos") {
                selectedDiagonal = "Diagonal 2"; showCamera = true
            }
            Button("Wipe Photos & Masks", role: .destructive) {
                if let base = folderURL { clearDiagonal(named: "Diagonal 2", at: base) }
                refreshCompletionStates()
                NotificationCenter.default.post(name: .diagonalPhotosSaved, object: nil, userInfo: ["diagonal": "Diagonal 2"]) 
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear { refreshCompletionStates() }
        .onReceive(NotificationCenter.default.publisher(for: .diagonalPhotosSaved)) { _ in
            refreshCompletionStates()
        }
        .onReceive(NotificationCenter.default.publisher(for: .centerReferenceSaved)) { _ in
            centerComplete = true
        }
        .sheet(isPresented: $showCenterCamera) {
            if let project = project {
                NavigationView {
                    CenterReferenceCameraView(project: project)
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Done") {
                                    showCenterCamera = false
                                }
                            }
                        }
                }
            } else {
                EmptyView()
            }
        }
    }
    
    private func refreshCompletionStates() {
        if let project = project {
            d1Complete = project.diagonal1Photos > 0
            d2Complete = project.diagonal2Photos > 0
            centerComplete = project.hasCenterReference
        }
    }

    private func clearDiagonal(named name: String, at base: URL) {
        let fm = FileManager.default
        let photos = base.appendingPathComponent(name).appendingPathComponent("Photos")
        let masks  = base.appendingPathComponent(name).appendingPathComponent("Masks")
        for dir in [photos, masks] {
            if let items = try? fm.contentsOfDirectory(atPath: dir.path) {
                for item in items {
                    let url = dir.appendingPathComponent(item)
                    try? fm.removeItem(at: url)
                }
            }
        }
    }
}

// MARK: - Center Reference Project Section
struct CenterReferenceProjectSection: View {
    let project: Project
    @State private var showCenterCamera = false
    
    var body: some View {
        LiquidGlassCard(cornerRadius: 14) {
            VStack(alignment: .leading, spacing: 10) {
                // Compact header
                HStack(spacing: 10) {
                    Image(systemName: "target")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.orange)
                        .frame(width: 22, height: 22)
                        .liquidGlassCircle(strokeOpacity: 0.25, shadowRadius: 3)
                    Text("Center Reference")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .glassText()
                    Spacer()
                    HStack(spacing: 6) {
                        Circle().fill(project.hasCenterReference ? Color.green : Color.orange).frame(width: 8, height: 8)
                        Text(project.hasCenterReference ? "Captured" : "Pending")
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundColor(project.hasCenterReference ? .green : .orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                }

                if project.hasCenterReference {
                    // Compact reference row
                    NavigationLink(destination: CenterReferenceDetailView(project: project)) {
                        HStack(spacing: 10) {
                            CenterReferenceThumbnail(project: project)
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 4) {
                                if let date = project.centerImageDate {
                                    Text("Captured \(date.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.system(.caption, design: .rounded))
                                        .glassTextSecondary()
                                }
                                if let latitude = project.centerImageLatitude, let longitude = project.centerImageLongitude {
                                    Text("\(String(format: "%.4f", latitude)), \(String(format: "%.4f", longitude))")
                                        .font(.system(.caption2, design: .rounded).weight(.medium))
                                        .glassTextSecondary()
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }

                    HStack { Spacer()
                        Button(action: { showCenterCamera = true }) {
                            Label("Replace", systemImage: "arrow.triangle.2.circlepath")
                                .font(.system(.footnote, design: .rounded).weight(.semibold))
                        }
                        .buttonStyle(.bordered)
                    Spacer() }
                } else {
                    // Pending state
                    Text("Position under the canopy center and capture a reference.")
                        .font(.system(.caption, design: .rounded))
                        .glassTextSecondary()
                        .frame(maxWidth: .infinity, alignment: .center)
                    HStack { Spacer()
                        Button(action: { showCenterCamera = true }) {
                            Label("Capture Center Reference", systemImage: "camera.macro.circle")
                                .font(.system(.footnote, design: .rounded).weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                    Spacer() }
                }
            }
            .padding(12)
        }
        .fullScreenCover(isPresented: $showCenterCamera) {
            if let project = project as? Project {
                CenterReferenceCameraView(project: project)
            }
        }
    }
}
