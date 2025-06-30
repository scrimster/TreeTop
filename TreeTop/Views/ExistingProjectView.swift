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
            .onDelete(perform: deleteProject)
        }
        .navigationTitle("All Projects")
        .task {
            await loadProjects()
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
            modelContext.delete(project)
            
            do {
                if let folderURL = project.folderURL {
                    if FileManager.default.fileExists(atPath: folderURL.path) {
                        try FileManager.default.removeItem(at: folderURL)
                    }
                }
            } catch {
                print("failed to delete folder: \(error.localizedDescription)")
            }
        }
        Task {
            await loadProjects()
        }
    }
}

#Preview {
    ExistingProjectView()
}
