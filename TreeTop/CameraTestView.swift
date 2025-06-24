//
//  ContentView.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 6/17/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        LiveCameraView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
