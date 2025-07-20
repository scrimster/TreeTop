//
//  TreeTopApp.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 6/17/25.
//

import SwiftUI
import SwiftData

@main
struct TreeTopApp: App {
    @State private var isLoading = true
    @State private var modelContainer: ModelContainer?
    @State private var initializationError: String?

    var body: some Scene {
        WindowGroup {
            Group {
                if let error = initializationError {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        Text("Initialization Error")
                            .font(.title)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else if let container = modelContainer {
                    ContentView()
                        .modelContainer(container)
                } else {
                    LoadingView()
                }
            }
            .onAppear {
                initializeModelContainer()
            }
        }
    }
    
    private func initializeModelContainer() {
        // Show loading immediately but don't block UI
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let schema = Schema([Project.self])
                let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                
                DispatchQueue.main.async {
                    // Initialize ProjectManager on main thread to access mainContext
                    let projectManager = ProjectManager(modelContext: container.mainContext)
                    ProjectManager.shared = projectManager
                    self.modelContainer = container
                    self.isLoading = false
                    
                    // Preload data after UI is shown to improve perceived performance
                    ProjectManager.shared.preloadData()
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.initializationError = "Could not initialize database: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}
