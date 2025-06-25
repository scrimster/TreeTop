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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Project.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if isLoading {
                    LoadingView()
                 } else {
                    ContentView()
        }
    }
        .onAppear {
            //simulate a short loading period
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isLoading = false
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
