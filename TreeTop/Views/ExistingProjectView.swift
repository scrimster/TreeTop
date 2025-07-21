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
            
            if projects.isEmpty {
                // Empty state
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
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(projects, id: \.id) { project in
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Your Projects")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if !projects.isEmpty {
                    Button(isEditMode ? "Done" : "Edit") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditMode.toggle()
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
        
    func loadProjects() async {
        let fetchDescriptor = FetchDescriptor<Project>()
        do{
            if let context = ProjectManager.shared?.modelContext {
                let fetched = try context.fetch(fetchDescriptor)
                self.projects = fetched
            }
        } catch {
            print("failed to fetch projects: \(error)")
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
                        .glassText()
                        .lineLimit(2)
                    
                    Text(project.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(.caption, design: .rounded))
                        .glassTextSecondary()
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .glassTextSecondary(opacity: 0.5)
            }
            .padding(16)
        }
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

#Preview {
    ExistingProjectView()
}
