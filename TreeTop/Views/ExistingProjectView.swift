//
//  ExistingProjectView.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 6/29/25.
//
//  REFACTORED - Components have been extracted into separate files:
//  - ProjectSearchBar.swift
//  - ProjectCard.swift
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
                        ProjectSearchBar(searchText: $searchText)
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
                                    NavigationLink(destination: FolderContentsView(folderURL: project.folderURL, project: project)) {
                                        ProjectCard(
                                            project: project,
                                            isEditMode: isEditMode,
                                            onDelete: { projectToDelete = project; showDeleteConfirmation = true },
                                            onRename: { projectToRename = project; newProjectName = project.name; showRenameDialog = true },
                                            onTap: nil
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
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
    
    // MARK: - Helper Functions
    
    func loadProjects() async {
        let fetchDescriptor = FetchDescriptor<Project>()
        do {
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
            // Failed to fetch projects
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
                        // Successfully deleted project folder
                    }
                }
            } catch {
                // Failed to delete project folder
            }
            
            // Save the context to persist the deletion
            do {
                try modelContext.save()
                // Project deleted from database
            } catch {
                // Failed to save context after deletion
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
            // Project renamed successfully
        } catch {
            // Failed to save renamed project
        }
        
        // Refresh the project list
        Task {
            await loadProjects()
        }
    }
}

// MARK: - Extensions

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

// MARK: - Preview

#Preview {
    ExistingProjectView()
}
