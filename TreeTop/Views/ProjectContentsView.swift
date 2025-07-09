import SwiftUI
import UIKit

struct ProjectContentsView: View {
    let project: Project
    @State private var showDiagonal1Camera = false
    @State private var showDiagonal2Camera = false
    @State private var summaryText: String? = nil

    var body: some View {
        List {
            Section("Project Info") {
                Text(project.name)
                Text(project.date.formatted(date: .abbreviated, time: .shortened))
            }

            Section("Diagonal 1") {
                NavigationLink("View Originals", destination: ImageListView(folderURL: subfolderURL("Diagonal1/Originals")))
                NavigationLink("View Masks", destination: ImageListView(folderURL: subfolderURL("Diagonal1/Masks")))
                Button("Capture Image") { showDiagonal1Camera = true }
                Button("Run Analysis") { runAnalysis(diagonal: "Diagonal1") }
            }

            Section("Diagonal 2") {
                NavigationLink("View Originals", destination: ImageListView(folderURL: subfolderURL("Diagonal2/Originals")))
                NavigationLink("View Masks", destination: ImageListView(folderURL: subfolderURL("Diagonal2/Masks")))
                Button("Capture Image") { showDiagonal2Camera = true }
                Button("Run Analysis") { runAnalysis(diagonal: "Diagonal2") }
            }

            Section {
                Button("Create Summary") { createSummary() }
                if let summaryText = summaryText {
                    Text(summaryText)
                }
            }
        }
        .navigationTitle("Project Contents")
        .sheet(isPresented: $showDiagonal1Camera) {
            LiveCameraView(project: project, shouldGoToExistingProjects: .constant(false), subfolder: "Diagonal1/Originals")
        }
        .sheet(isPresented: $showDiagonal2Camera) {
            LiveCameraView(project: project, shouldGoToExistingProjects: .constant(false), subfolder: "Diagonal2/Originals")
        }
    }

    func subfolderURL(_ sub: String) -> URL? {
        project.folderURL?.appendingPathComponent(sub)
    }

    func runAnalysis(diagonal: String) {
        // Placeholder for ML processing
        if let avg = ProjectManager.shared.analyzeImages(in: diagonal, for: project) {
            summaryText = "Average canopy for \(diagonal): \(String(format: "%.2f", avg * 100))%"
        }
    }

    func createSummary() {
        if let total = ProjectManager.shared.createSummary(for: project) {
            summaryText = "Project Average Canopy: \(String(format: "%.2f", total * 100))%"
        }
    }
}

struct ImageListView: View {
    let folderURL: URL?
    @State private var files: [String] = []

    var body: some View {
        List(files, id: \.
self) { file in
            if file.lowercased().hasSuffix(".jpg") {
                NavigationLink(destination: ImageViewerView(imageURL: folderURL?.appendingPathComponent(file))) {
                    Text(file)
                }
            } else {
                Text(file)
            }
        }
        .navigationTitle(folderURL?.lastPathComponent ?? "Images")
        .onAppear { loadFolderContents() }
    }

    func loadFolderContents() {
        guard let folderURL = folderURL else { return }
        do {
            let fileNames = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
            self.files = fileNames
        } catch {
            print("failed to read folder: \(error)")
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
}

#Preview {
    ProjectContentsView(project: Project(name: "Preview", date: Date(), folderName: "Preview"))
}
