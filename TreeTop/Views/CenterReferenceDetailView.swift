import SwiftUI
import CoreLocation

struct CenterReferenceDetailView: View {
    let project: Project
    @State private var centerImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Breathing animated background
            AnimatedForestBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Center Reference Image
                    if let image = centerImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 400)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 300)
                            .overlay(
                                VStack(spacing: 12) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .glassTextSecondary(opacity: 0.5)
                                    Text("No center reference image")
                                        .font(.system(.body, design: .rounded))
                                        .glassTextSecondary(opacity: 0.7)
                                }
                            )
                    }
                    
                    // Metadata Card
                    LiquidGlassCard(cornerRadius: 16) {
                        VStack(alignment: .leading, spacing: 16) {
                            // Header
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 20))
                                    .glassText()
                                
                                Text("Reference Details")
                                    .font(.system(.title2, design: .rounded, weight: .semibold))
                                    .glassText()
                                
                                Spacer()
                            }
                            
                            // Date Information
                            if let date = project.centerImageDate {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Captured")
                                        .font(.system(.caption, design: .rounded, weight: .semibold))
                                        .glassTextSecondary(opacity: 0.7)
                                    
                                    Text(date.formatted(date: .abbreviated, time: .standard))
                                        .font(.system(.body, design: .rounded))
                                        .glassText()
                                }
                            }
                            
                            // Location Information
                            if let lat = project.centerImageLatitude,
                               let lon = project.centerImageLongitude {
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Location")
                                        .font(.system(.caption, design: .rounded, weight: .semibold))
                                        .glassTextSecondary(opacity: 0.7)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text("Latitude:")
                                                .font(.system(.caption, design: .rounded))
                                                .glassTextSecondary(opacity: 0.8)
                                            Text(String(format: "%.6f°", lat))
                                                .font(.system(.body, design: .rounded, weight: .medium))
                                                .glassText()
                                        }
                                        
                                        HStack {
                                            Text("Longitude:")
                                                .font(.system(.caption, design: .rounded))
                                                .glassTextSecondary(opacity: 0.8)
                                            Text(String(format: "%.6f°", lon))
                                                .font(.system(.body, design: .rounded, weight: .medium))
                                                .glassText()
                                        }
                                        
                                        if let elevation = project.centerImageElevation {
                                            HStack {
                                                Text("Elevation:")
                                                    .font(.system(.caption, design: .rounded))
                                                    .glassTextSecondary(opacity: 0.8)
                                                Text(String(format: "%.1f m", elevation))
                                                    .font(.system(.body, design: .rounded, weight: .medium))
                                                    .glassText()
                                            }
                                        }
                                    }
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Location")
                                        .font(.system(.caption, design: .rounded, weight: .semibold))
                                        .glassTextSecondary(opacity: 0.7)
                                    
                                    Text("No location data available")
                                        .font(.system(.body, design: .rounded))
                                        .glassTextSecondary(opacity: 0.6)
                                }
                            }
                            
                            // File Information
                            if let fileName = project.centerImageFileName {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("File")
                                        .font(.system(.caption, design: .rounded, weight: .semibold))
                                        .glassTextSecondary(opacity: 0.7)
                                    
                                    Text(fileName)
                                        .font(.system(.caption, design: .rounded))
                                        .glassTextSecondary(opacity: 0.8)
                                }
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
        }
        .navigationTitle("Center Reference")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCenterImage()
        }
    }
    
    private func loadCenterImage() {
        Task {
            let image = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let fullImage = ProjectManager.shared?.getCenterReferenceImage(for: project)
                    continuation.resume(returning: fullImage)
                }
            }
            
            await MainActor.run {
                centerImage = image
            }
        }
    }
}

#Preview {
    NavigationView {
        // This would need a mock project for preview
        Text("Center Reference Detail Preview")
    }
}
