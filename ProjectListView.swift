
import SwiftUI

struct Project: Identifiable {
    let id = UUID()
    let name: String
    let dateCreated: Date
}

struct ProjectListView: View {
    @State private var projects: [Project] = [
        Project(name: "Project 1", dateCreated: Date()),
        Project(name: "Project 2", dateCreated: Date().addingTimeInterval(-86400)),
        Project(name: "Project 3", dateCreated: Date().addingTimeInterval(-172800))
    ]

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(projects) { project in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(project.name)
                                    .font(.headline)
                                    .bold()

                                HStack {
                                    Text(project.dateCreated, format: Date.FormatStyle(date: .numeric, time: .omitted))
                                    Text(project.dateCreated, format: Date.FormatStyle(date: .omitted, time: .shortened))
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color(.systemBackground))
                .listStyle(.plain)

                // New Project button
                Button(action: {
                }) {
                    Text("+ New Project")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(16)
                        .padding(.horizontal)
                }
                .padding(.bottom, 16)
            }
            .navigationTitle("TreeTop")
        }
    }
}
