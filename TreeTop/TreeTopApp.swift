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
                        .onAppear {
                            print("📱 App showing LoadingView - isLoading: \(isLoading), modelContainer: \(modelContainer != nil)")
                        }
                }
            }
            .task {
                // Use .task instead of .onAppear for better async handling
                print("🚀 App task started - initializing model container")
                initializeModelContainer()
            }
        }
    }
    
    private func initializeModelContainer() {
        sendLoadingMessage("Starting initialization...")
        print("⏱️ Starting ModelContainer initialization...")
        
        // Add a small delay so users can see the loading screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Show loading immediately but don't block UI
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    DispatchQueue.main.async {
                        self.sendLoadingMessage("Creating database schema...")
                    }
                    print("🔧 Creating schema and configuration...")
                    let schema = Schema([Project.self])
                    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                    
                    // Small delay to show the message
                    Thread.sleep(forTimeInterval: 0.2)
                    
                    DispatchQueue.main.async {
                        self.sendLoadingMessage("Setting up database container...")
                    }
                    print("📦 Creating ModelContainer...")
                    let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                    
                    print("✅ ModelContainer created successfully, switching to main thread...")
                    DispatchQueue.main.async {
                        self.sendLoadingMessage("Finalizing setup...")
                        print("🎯 On main thread - initializing ProjectManager...")
                        // Initialize ProjectManager on main thread to access mainContext
                        let projectManager = ProjectManager(modelContext: container.mainContext)
                        ProjectManager.shared = projectManager
                        self.modelContainer = container
                        
                        // Small delay before showing main app
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.isLoading = false
                            print("🎉 Initialization complete! App should show ContentView now.")
                            
                            // Preload data after UI is shown to improve perceived performance
                            ProjectManager.shared.preloadData()
                        }
                    }
                    
                } catch {
                    print("❌ ModelContainer initialization failed: \(error)")
                    DispatchQueue.main.async {
                        self.initializationError = "Could not initialize database: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    private func sendLoadingMessage(_ message: String) {
        NotificationCenter.default.post(name: .initializationMessage, object: message)
    }
}
