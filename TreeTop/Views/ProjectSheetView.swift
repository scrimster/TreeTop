//
//  ProjectSheetView.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 8/7/25.
//

import SwiftUI

struct ProjectSheetView: View {
    @State private var searchText: String = ""

    let projects: [Project]
    @Binding var selectedProject: Project?
    var onSelect: ((Project) -> Void)? = nil

    var sortedProjects: [Project] {
        projects.sorted { $0.date > $1.date }
    }

    var filteredProjects: [Project] {
        if searchText.isEmpty {
            return sortedProjects
        } else {
            return sortedProjects.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 🔠 Title and search bar
            Text("Your Projects")
                .font(.title2.bold())
                .padding(.top, 24)
                .padding(.horizontal)

            TextField("Search projects...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            // 📄 Project list
            List(filteredProjects, id: \.self) { project in
                Button {
                    onSelect?(project)
                } label: {
                    HStack(spacing: 12) {
                        // 🖼 Thumbnail or placeholder
                        if let image = ProjectManager.shared.getCenterReferenceThumbnail(for: project) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        }

                        // 📋 Project info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(project.name)
                                .font(.headline)
                                .foregroundColor(.primary)

                            if let canopy = project.canopyCoverPercentage {
                                Text("Canopy: \(canopy, specifier: "%.1f")%")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }

                            Text("Created: \(project.date.formatted(.dateTime.month().day().year()))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(project == selectedProject ? Color.blue.opacity(0.15) : Color.clear)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .listStyle(.plain)
        }
    }
}
