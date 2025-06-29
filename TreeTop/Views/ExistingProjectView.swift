//
//  ExistingProjectView.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 6/29/25.
//

import SwiftUI
import SwiftData

struct ExistingProjectView: View {
    @State var projects: [Project] = []
    var body: some View {
        NavigationView {
            List(projects, id: \.id) { project in NavigationLink (destination: FolderContentsView( folderURL: project.folderURL)) {
                VStack(alignment: .leading) {
                    Text(project.name)
                        .font(.headline)
                    Text(project.date.formatted(date: .long, time: .shortened))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("All Projects")
            .onAppear{
                loadProjects()
            }
            }
        }
        
        func loadProjects(){
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
    }

#Preview {
    ExistingProjectView()
}
