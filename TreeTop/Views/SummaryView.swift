//
//  ContentView.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 6/17/25.
//

import SwiftUI
import SwiftData

struct SummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @StateObject private var captureViewModel = CaptureViewModel()

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
                ToolbarItem {
                    Button(action: saveMockSummary) {
                        Label("Save Summary", systemImage: "square.and.arrow.down")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
    private func saveSummaryWithRealData(image: UIImage, canopyPercent: Double, location: CLLocationCoordinate2D) {
        captureViewModel.saveSummary(
            image: image,
            canopyPercent: canopyPercent,
            location: location
        )
        
        print("Saved summary with TreeTop: \(canopyPercent)% at \(location.latitude), \(location.longitude)")
    }
}

#Preview {
    SummaryView()
        .modelContainer(for: Item.self, inMemory: true)
}
