//
//  DiagonalFolderView.swift
//  TreeTop
//
//

import SwiftUI
import Foundation

/// Displays diagonal folder information and controls
struct DiagonalFolderView<PhotosLink: View>: View {
    let title: String
    let photosCount: Int
    let masksCount: Int
    let onCapture: () -> Void
    let photosLink: PhotosLink
    let masksLinkURL: URL
    
    var body: some View {
        LiquidGlassCard(cornerRadius: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title)
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .glassText()
                    Spacer()
                    Button(action: onCapture) { 
                        Label("Capture", systemImage: "camera") 
                    }
                    .buttonStyle(.bordered)
                }
                HStack(spacing: 10) {
                    chip(text: "Photos: \(photosCount)", color: .blue)
                    chip(text: "Masks: \(masksCount)", color: .green)
                    Spacer()
                }
                HStack(spacing: 10) {
                    NavigationLink(destination: photosLink) {
                        Label("Open Photos", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(.bordered)
                    NavigationLink(destination: FolderContentsView(folderURL: masksLinkURL, project: nil)) {
                        Label("Open Masks", systemImage: "rectangle.on.rectangle")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(14)
        }
    }
    
    private func chip(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(.caption, design: .rounded).weight(.medium))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

#Preview {
    DiagonalFolderView(
        title: "Diagonal 1",
        photosCount: 5,
        masksCount: 3,
        onCapture: {},
        photosLink: AnyView(Text("Photos")),
        masksLinkURL: URL(fileURLWithPath: "/test")
    )
    .background(AnimatedForestBackground())
}
