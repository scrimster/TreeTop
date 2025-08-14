//
//  ProjectSearchBar.swift
//  TreeTop
//
//  Created by TreeTop Team on 7/20/25.
//

import SwiftUI
import Foundation

/// Search bar for filtering projects
struct ProjectSearchBar: View {
    // MARK: - Properties
    
    @Binding var searchText: String
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 16))
                
                TextField("Search projects...", text: $searchText)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.white)
                    .placeholder(when: searchText.isEmpty) {
                        Text("Search projects...")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(.body, design: .rounded))
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .liquidGlass(cornerRadius: 12)
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }
}

#Preview {
    ProjectSearchBar(searchText: .constant(""))
        .background(AnimatedForestBackground())
}
