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
    @State var showDeleteAlert = false
    @State var projectToDelete: Project?
    
    var body: some View {
        List {
            ForEach(projects, id: \.id) { project in
                NavigationLink (destination: FolderContentsView(folderURL: project.folderURL)) {
                    VStack(alignment: .leading) {
                        Text(project.name)
                            .font(.headline)
                        Text(project.date.formatted(date: .long, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete { indexSet in
                if let index = indexSet.first {
                    projectToDelete = projects[index]
                    showDeleteAlert = true
                }
            }
        }
        .navigationTitle("All Projects")
        .task {
            await loadProjects()
        }
        .alert("Are you sure you want to delete this project?",
               isPresented: $showDeleteAlert,
               actions: {
            Button("Delete", role: .destructive) {
                if let project = projectToDelete {
                    ProjectManager.shared?.delete(project)
                    Task {
                        await loadProjects()
                    }
                    projectToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                projectToDelete = nil
            }
        },
        message: {Text("This will permanently remove the project and all its folders.")
        })
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
            ProjectManager.shared?.delete(project)
        }
        Task {
            await loadProjects()
        }
    }
}

#Preview {
    ExistingProjectView()
}
