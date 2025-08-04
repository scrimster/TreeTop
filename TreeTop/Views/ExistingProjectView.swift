//
//  ExistingProjectView.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 6/29/25.
//

import SwiftUI
import SwiftData

struct ExistingProjectView: View {
    @Environment(\.modelContext) var modelContext
    @State var projects: [Project] = []
    @State var filteredProjects: [Project] = []
    @State var searchText: String = ""
    @State private var projectToDelete: Project?
    @State private var showDeleteConfirmation = false
    @State private var isEditMode = false
    @State private var projectToRename: Project?
    @State private var newProjectName = ""
    @State private var showRenameDialog = false
    @State private var showRenameDuplicateAlert = false
    
    var body: some View {
        ZStack {
            // Breathing animated background
            AnimatedForestBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false) // Prevent background from intercepting touches
            
            if projects.isEmpty {
                // Empty state when no projects exist at all
                VStack(spacing: 24) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(spacing: 8) {
                        Text("No Projects Yet")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Create your first forest analysis project to get started")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            } else {
                // Main content with search bar and projects
                VStack(spacing: 0) {
                    // Search bar (always visible when projects exist, hidden in edit mode)
                    if !isEditMode {
                        HStack {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.white.opacity(0.6))
                                    .font(.system(size: 16))
                                
                                TextField("Search projects...", text: $searchText)
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.white)
                                    .placeholder(when: searchText.isEmpty) {
                                        Text("Search projects...")
                                            .foregroundColor(.white.opacity(0.5))
                                            .font(.system(.body, design: .rounded))
                                    }
                                
                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white.opacity(0.6))
                                            .font(.system(size: 16))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                    
                    // Content area
                    if filteredProjects.isEmpty && !searchText.isEmpty {
                        // Search results empty state
                        Spacer()
                        VStack(spacing: 24) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.6),
                                            Color.white.opacity(0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            VStack(spacing: 8) {
                                Text("No Projects Found")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("No projects match '\(searchText)'")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        Spacer()
                    } else {
                        // Projects list
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredProjects, id: \.id) { project in
                                    if isEditMode {
                                        EditableProjectCard(
                                            project: project,
                                            onDelete: {
                                                projectToDelete = project
                                                showDeleteConfirmation = true
                                            },
                                            onRename: {
                                                projectToRename = project
                                                newProjectName = project.name
                                                showRenameDialog = true
                                            }
                                        )
                                    } else {
                                        NavigationLink(destination: FolderContentsView(folderURL: project.folderURL, project: project)) {
                                            ProjectCard(project: project)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: searchText) { _, _ in
            updateFilteredProjects()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Your Projects")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if !searchText.isEmpty && !projects.isEmpty {
                        Text("\(filteredProjects.count) of \(projects.count)")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if !projects.isEmpty {
                    Button(isEditMode ? "Done" : "Edit") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditMode.toggle()
                            // Clear search when entering edit mode
                            if isEditMode {
                                searchText = ""
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .font(.system(.body, weight: .medium))
                }
            }
        }
        .task {
            await loadProjects()
        }
        .refreshable {
            await loadProjects()
        }
        .confirmationDialog(
            "Delete Project",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let project = projectToDelete,
                   let index = projects.firstIndex(where: { $0.id == project.id }) {
                    deleteProject(at: IndexSet(integer: index))
                }
                projectToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                projectToDelete = nil
            }
        } message: {
            if let project = projectToDelete {
                Text("Are you sure you want to delete '\(project.name)'? This action cannot be undone and will remove all associated data.")
            }
            Button("Cancel", role: .cancel) {
                projectToDelete = nil
            }
        }
        .alert("Rename Project", isPresented: $showRenameDialog) {
            TextField("Project Name", text: $newProjectName)
            Button("Rename") {
                if let project = projectToRename {
                    renameProject(project, to: newProjectName)
                }
                projectToRename = nil
            }
            Button("Cancel", role: .cancel) {
                projectToRename = nil
                newProjectName = ""
            }
        } message: {
            Text("Enter a new name for the project")
        }
        .alert("Project Name Already Exists", isPresented: $showRenameDuplicateAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A project with this name already exists. Please choose a different name.")
        }
    }

    func loadProjects() async {
        let fetchDescriptor = FetchDescriptor<Project>()
        do{
            if let context = ProjectManager.shared?.modelContext {
                let fetched = try context.fetch(fetchDescriptor)
                // Sort projects alphabetically by name
                self.projects = fetched.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                
                // Update filtered projects
                updateFilteredProjects()
                
                // Refresh statistics for all projects
                refreshAllProjectStatistics()
            }
        } catch {
            print("failed to fetch projects: \(error)")
        }
    }
    
    private func updateFilteredProjects() {
        if searchText.isEmpty {
            filteredProjects = projects
        } else {
            filteredProjects = projects.filter { project in
                project.name.localizedCaseInsensitiveCompare(searchText) == .orderedSame ||
                project.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func refreshAllProjectStatistics() {
        for project in projects {
            ProjectManager.shared?.refreshProjectStatistics(project)
        }
    }
    
    func deleteProject(at offsets: IndexSet) {
        for index in offsets {
            let project = projects[index]
            
            // Remove from SwiftData
            modelContext.delete(project)
            
            // Remove the folder and all its contents
            do {
                if let folderURL = project.folderURL {
                    if FileManager.default.fileExists(atPath: folderURL.path) {
                        try FileManager.default.removeItem(at: folderURL)
                        print("✅ Successfully deleted project folder: \(folderURL.path)")
                    }
                }
            } catch {
                print("❌ Failed to delete project folder: \(error.localizedDescription)")
            }
            
            // Save the context to persist the deletion
            do {
                try modelContext.save()
                print("✅ Project deleted from database")
            } catch {
                print("❌ Failed to save context after deletion: \(error.localizedDescription)")
            }
        }
        
        // Refresh the project list
        Task {
            await loadProjects()
        }
    }
    
    func renameProject(_ project: Project, to newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Check if the name is the same (case-insensitive)
        if project.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedName.lowercased() {
            // Same name, no need to rename
            return
        }
        
        // Check for duplicate names (excluding the current project)
        let trimmedLowerName = trimmedName.lowercased()
        let nameExists = projects.contains { existingProject in
            existingProject.id != project.id &&
            existingProject.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedLowerName
        }
        
        if nameExists {
            showRenameDuplicateAlert = true
            return
        }
        
        project.name = trimmedName
        
        do {
            try modelContext.save()
            print("✅ Project renamed to: \(trimmedName)")
        } catch {
            print("❌ Failed to save renamed project: \(error.localizedDescription)")
        }
        
        // Refresh the project list
        Task {
            await loadProjects()
        }
    }
}

struct ProjectCard: View {
    let project: Project
    
    var body: some View {
        LiquidGlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with project name, date, status, and center reference
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                            .font(.system(.title2, design: .rounded, weight: .semibold))
                            .glassText()
                            .lineLimit(2)
                        
                        Text(project.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(.caption, design: .rounded))
                            .glassTextSecondary(opacity: 0.7)
                    }
                    
                    Spacer()
                    
                    // Center reference thumbnail
                    if project.hasCenterReference {
                        NavigationLink(destination: CenterReferenceDetailView(project: project)) {
                            VStack(spacing: 4) {
                                CenterReferenceThumbnail(project: project)
                                
                                Text("Center Ref")
                                    .font(.system(.caption2, design: .rounded))
                                    .glassTextSecondary(opacity: 0.6)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    VStack(spacing: 4) {
                        // Out of date indicator
                        if project.isAnalysisOutOfDate && project.canopyCoverPercentage != nil {
                            VStack(spacing: 2) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                                
                                Text("Needs Rebake")
                                    .font(.system(.caption2, design: .rounded, weight: .medium))
                                    .glassTextSecondary(opacity: 0.8)
                            }
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .glassTextSecondary(opacity: 0.5)
                    }
                }
                
                // Statistics Section
                if let canopyPercentage = project.canopyCoverPercentage {
                    HStack(spacing: 20) {
                        // Canopy Cover
                        StatisticItem(
                            icon: "leaf.fill",
                            title: "Canopy Cover",
                            value: "\(Int(canopyPercentage))%",
                            color: .green
                        )
                        
                        // Photo Count
                        StatisticItem(
                            icon: "camera.fill",
                            title: "Photos",
                            value: "\(project.totalPhotos)",
                            color: .blue
                        )
                        
                        // Last Analysis
                        if let analysisDate = project.lastAnalysisDate {
                            StatisticItem(
                                icon: "clock.fill",
                                title: "Analyzed",
                                value: formatRelativeDate(analysisDate),
                                color: .purple
                            )
                        }
                    }
                } else {
                    // No analysis yet
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14))
                            .glassTextSecondary(opacity: 0.6)
                        
                        Text("No analysis available")
                            .font(.system(.subheadline, design: .rounded))
                            .glassTextSecondary(opacity: 0.6)
                        
                        Spacer()
                        
                        // Show photo counts even without analysis
                        if project.totalPhotos > 0 {
                            Text("\(project.totalPhotos) photos")
                                .font(.system(.caption, design: .rounded))
                                .glassTextSecondary(opacity: 0.7)
                        }
                    }
                }
                
                // Progress indicators for diagonals
                if project.diagonal1Photos > 0 || project.diagonal2Photos > 0 {
                    HStack(spacing: 12) {
                        DiagonalProgress(
                            number: 1,
                            count: project.diagonal1Photos
                        )
                        
                        DiagonalProgress(
                            number: 2,
                            count: project.diagonal2Photos
                        )
                        
                        Spacer()
                    }
                }
            }
            .padding(20)
        }
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct EditableProjectCard: View {
    let project: Project
    let onDelete: () -> Void
    let onRename: () -> Void
    
    var body: some View {
        LiquidGlassCard(cornerRadius: 18) {
            HStack(spacing: 16) {
                // Project icon
                Image(systemName: "folder.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.8, blue: 0.6),
                                Color(red: 0.3, green: 0.7, blue: 0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(2)
                    
                    Text(project.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Action buttons with liquid glass circles
                HStack(spacing: 10) {
                    Button(action: onRename) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(10)
                            .liquidGlassCircle(strokeOpacity: 0.4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(10)
                            .liquidGlassCircle(strokeOpacity: 0.4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(16)
        }
    }
}

struct StatisticItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .glassText()
            
            Text(title)
                .font(.system(.caption2, design: .rounded))
                .glassTextSecondary(opacity: 0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DiagonalProgress: View {
    let number: Int
    let count: Int
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 12))
                .glassTextSecondary(opacity: 0.7)
            
            Text("D\(number): \(count)")
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .glassTextSecondary(opacity: 0.7)
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct CenterReferenceThumbnail: View {
    let project: Project
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        Group {
            if let image = thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 16))
                            .glassTextSecondary(opacity: 0.5)
                    )
            }
        }
        .onAppear {
            loadThumbnail()
        }
        .onChange(of: project.centerImageFileName) { _, _ in
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        guard project.hasCenterReference else {
            thumbnailImage = nil
            return
        }
        
        // Load on background queue to avoid blocking UI
        Task {
            let image = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let thumbnail = ProjectManager.shared?.getCenterReferenceThumbnail(for: project)
                    continuation.resume(returning: thumbnail)
                }
            }
            
            await MainActor.run {
                thumbnailImage = image
            }
        }
    }
}

#Preview {
    ExistingProjectView()
}
