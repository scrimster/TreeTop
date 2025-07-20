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
    @State private var modelContainer: ModelContainer?
    @State private var initializationError: String?

    var body: some Scene {
        WindowGroup {
            Group {
                if let error = initializationError {
                    // Error state with themed background
                    ZStack {
                        AnimatedForestBackground()
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.white)
                            Text("Initialization Error")
                                .font(.title)
                                .foregroundColor(.white)
                            Text(error)
                                .multilineTextAlignment(.center)
                                .padding()
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                } else if let container = modelContainer {
                    ContentView()
                        .modelContainer(container)
                } else {
                    // Show loading immediately - no conditions
                    LoadingView()
                }
            }
            .onAppear {
                // Start initialization immediately when the view appears
                if modelContainer == nil && initializationError == nil {
                    print("🚀 App appeared - triggering immediate initialization")
                    // Start on main thread to avoid any thread switching delays
                    initializeModelContainer()
                }
            }
        }
    }
    
    private func initializeModelContainer() {
        print("⏱️ Starting ultra-fast ModelContainer initialization...")
        
        // Use highest priority for maximum speed - no UI updates until complete
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                print("🔧 Creating ModelContainer...")
                let schema = Schema([Project.self])
                let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                
                print("✅ ModelContainer created - completing on main thread")
                
                // Complete everything on main thread in one shot
                DispatchQueue.main.async {
                    // Initialize ProjectManager
                    let projectManager = ProjectManager(modelContext: container.mainContext)
                    ProjectManager.shared = projectManager
                    
                    // Complete initialization immediately - no delays
                    self.modelContainer = container
                    print("🎉 Ultra-fast initialization complete!")
                    
                    // Background preload - don't block anything
                    DispatchQueue.global(qos: .background).async {
                        ProjectManager.shared.preloadData()
                    }
                }
                
            } catch {
                print("❌ ModelContainer initialization failed: \(error)")
                DispatchQueue.main.async {
                    self.initializationError = "Database initialization failed"
                }
            }
        }
    }
    
    private func sendLoadingMessage(_ message: String) {
        NotificationCenter.default.post(name: .initializationMessage, object: message)
    }
}
