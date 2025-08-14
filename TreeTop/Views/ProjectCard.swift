//
//  ProjectCard.swift
//  TreeTop
//
//

import SwiftUI
import SwiftData
import Foundation

/// Project card component for displaying project information
struct ProjectCard: View {
    // MARK: - Properties
    
    let project: Project
    let isEditMode: Bool
    let onDelete: () -> Void
    let onRename: () -> Void
    let onTap: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        LiquidGlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with project name, date, status, and center reference
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                            .font(.system(.title2, design: .rounded, weight: .semibold))
                            .glassText()
                            .lineLimit(2)
                        
                        Text(project.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(.caption, design: .rounded))
                            .glassTextSecondary(opacity: 0.7)
                    }
                    
                    Spacer()
                    
                    // Center reference thumbnail
                    if project.hasCenterReference {
                        NavigationLink(destination: CenterReferenceDetailView(project: project)) {
                            VStack(spacing: 4) {
                                CenterReferenceThumbnail(project: project)
                                
                                Text("Center Ref")
                                    .font(.system(.caption2, design: .rounded))
                                    .glassTextSecondary(opacity: 0.6)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    VStack(spacing: 4) {
                        // Edit mode controls
                        if isEditMode {
                            HStack(spacing: 8) {
                                Button(action: onRename) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                }
                                Button(action: onDelete) {
                                    Image(systemName: "trash.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.red)
                                }
                            }
                        } else {
                            // Out of date indicator
                            if project.isAnalysisOutOfDate && project.canopyCoverPercentage != nil {
                                VStack(spacing: 2) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.orange)
                                    
                                    Text("Needs Rebake")
                                        .font(.system(.caption2, design: .rounded, weight: .medium))
                                        .glassTextSecondary(opacity: 0.8)
                                }
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .glassTextSecondary(opacity: 0.5)
                        }
                    }
                }
                
                // Statistics Section
                if let canopyPercentage = project.canopyCoverPercentage {
                    HStack(spacing: 20) {
                        // Canopy Cover
                        StatisticItem(
                            icon: "leaf.fill",
                            title: "Canopy Cover",
                            value: "\(Int(canopyPercentage))%",
                            color: .green
                        )
                        
                        // Photo Count
                        StatisticItem(
                            icon: "camera.fill",
                            title: "Photos",
                            value: "\(project.totalPhotos)",
                            color: .blue
                        )
                        
                        // Weather
                        StatisticItem(
                            icon: weatherIcon(for: project.weatherCondition),
                            title: "Weather",
                            value: project.weatherCondition ?? "—",
                            color: weatherColor(for: project.weatherCondition)
                        )
                        
                        // Last Analysis
                        if let analysisDate = project.lastAnalysisDate {
                            StatisticItem(
                                icon: "clock.fill",
                                title: "Analyzed",
                                value: formatRelativeDate(analysisDate),
                                color: .purple
                            )
                        }
                    }
                } else {
                    // No analysis yet
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14))
                            .glassTextSecondary(opacity: 0.6)
                        
                        Text("No analysis available")
                            .font(.system(.subheadline, design: .rounded))
                            .glassTextSecondary(opacity: 0.6)
                        
                        Spacer()
                        
                        // Show photo counts even without analysis
                        if project.totalPhotos > 0 {
                            Text("\(project.totalPhotos) photos")
                                .font(.system(.caption, design: .rounded))
                                .glassTextSecondary(opacity: 0.7)
                        }
                    }
                }
                
                // Progress indicators for diagonals
                if project.diagonal1Photos > 0 || project.diagonal2Photos > 0 {
                    HStack(spacing: 12) {
                        DiagonalProgress(
                            number: 1,
                            count: project.diagonal1Photos
                        )
                        
                        DiagonalProgress(
                            number: 2,
                            count: project.diagonal2Photos
                        )
                        
                        Spacer()
                    }
                }
            }
            .padding(20)
        }
        .modifier(TapGestureModifier(isEditMode: isEditMode, onTap: onTap))
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Helper Components

struct StatisticItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundColor(color)
                .padding(.top, 2)

            Text(value)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .glassText()
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .allowsTightening(true)

            Text(title)
                .font(.system(.caption2, design: .rounded))
                .glassTextSecondary(opacity: 0.7)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DiagonalProgress: View {
    let number: Int
    let count: Int
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 12))
                .glassTextSecondary(opacity: 0.7)
            
            Text(number == 1 ? "Diagonal 1 Photos: \(count)" : "Diagonal 2 Photos: \(count)")
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .glassTextSecondary(opacity: 0.7)
        }
    }
}

struct CenterReferenceThumbnail: View {
    let project: Project
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        Group {
            if let image = thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .liquidGlassCircle(strokeOpacity: 0.25, shadowRadius: 4)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 40, height: 40)
                    .liquidGlass(cornerRadius: 8, strokeOpacity: 0.25, shadowRadius: 4)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 16))
                            .glassTextSecondary(opacity: 0.5)
                    )
            }
        }
        .onAppear {
            loadThumbnail()
        }
        .onChange(of: project.centerImageFileName) { _, _ in
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        guard project.hasCenterReference else {
            thumbnailImage = nil
            return
        }
        
        // Load on background queue to avoid blocking UI
        Task {
            let image = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let thumbnail = ProjectManager.shared?.getCenterReferenceThumbnail(for: project)
                    continuation.resume(returning: thumbnail)
                }
            }
            
            await MainActor.run {
                thumbnailImage = image
            }
        }
    }
}

// MARK: - Weather helpers
private func weatherIcon(for condition: String?) -> String {
    switch condition {
    case "Clear": return "sun.max.fill"
    case "Partly Cloudy": return "cloud.sun.fill"
    case "Overcast": return "cloud.fill"
    case "Light Rain": return "cloud.drizzle.fill"
    case "Rain": return "cloud.rain.fill"
    case "Fog": return "cloud.fog.fill"
    case "Snow": return "snowflake"
    default: return "cloud.sun"
    }
}

private func weatherColor(for condition: String?) -> Color {
    switch condition {
    case "Clear": return .yellow
    case "Partly Cloudy": return .orange
    case "Overcast": return .gray
    case "Light Rain": return Color.blue.opacity(0.8)
    case "Rain": return .blue
    case "Fog": return .white.opacity(0.85)
    case "Snow": return .cyan
    default: return .white.opacity(0.8)
    }
}

struct TapGestureModifier: ViewModifier {
    let isEditMode: Bool
    let onTap: (() -> Void)?
    
    func body(content: Content) -> some View {
        if let onTap = onTap {
            content.onTapGesture {
                if !isEditMode {
                    onTap()
                }
            }
        } else {
            content
        }
    }
}

#Preview {
    ProjectCard(
        project: Project(name: "Test Project", date: Date(), folderName: "test", location: nil),
        isEditMode: false,
        onDelete: {},
        onRename: {},
        onTap: nil
    )
    .background(AnimatedForestBackground())
}
