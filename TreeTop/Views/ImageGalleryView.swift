//
//  ImageGalleryView.swift
//  TreeTop
//
//  Created by TreeTop Assistant on 7/20/25.
//

import SwiftUI
import Foundation

/// Displays a gallery of images with delete functionality
struct ImageGalleryView: View {
    let images: [UIImage]
    let onDelete: (Int) -> Void
    let onImageTap: (UIImage) -> Void
    
    var body: some View {
        if images.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.6))
                Text("No images found")
                    .font(.system(.body, design: .rounded))
                    .glassTextSecondary()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    ImageGalleryItem(
                        image: image,
                        onDelete: { onDelete(index) },
                        onTap: { onImageTap(image) }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

/// Individual image item in the gallery
struct ImageGalleryItem: View {
    let image: UIImage
    let onDelete: () -> Void
    let onTap: () -> Void
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: onTap) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { showDeleteAlert = true }) {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .alert("Delete Image", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this image?")
        }
    }
}



#Preview {
    ImageGalleryView(
        images: [],
        onDelete: { _ in },
        onImageTap: { _ in }
    )
    .background(AnimatedForestBackground())
}
