//
//  ProjectDataCard.swift
//  TreeTop
//
//  Created by TreeTop Team on 7/20/25.
//

import SwiftUI
import SwiftData
import Foundation

/// Project data display card
struct ProjectDataCard: View {
    // MARK: - Properties
    
    let project: Project
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Body
    
    var body: some View {
        let canopy = project.canopyCoverPercentage ?? 0
        let canopyColor: Color = canopyColorFor(canopy)
        
        LiquidGlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text(project.name)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .glassText()
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    Spacer()
                    // Canopy badge
                    HStack(spacing: 6) {
                        Circle().fill(canopyColor).frame(width: 8, height: 8)
                        Text(project.canopyCoverPercentage != nil ? String(format: "%.1f%%", canopy) : "—")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(canopyColor)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                }

                // Meta rows
                VStack(spacing: 10) {
                    metaRow(icon: "calendar", title: "Created", value: project.date.formatted(.dateTime.month().day().year()))
                    if let c = project.centerCoordinate {
                        metaRow(icon: "location.fill", title: "Coordinates", value: String(format: "%.5f, %.5f", c.latitude, c.longitude))
                    } else {
                        metaRow(icon: "location", title: "Coordinates", value: "—")
                    }
                    metaRow(icon: "mountain.2.fill", title: "Elevation", value: String(format: "%.1f m", project.elevation))
                    
                    // Weather picker
                    weatherPickerRow(project: project)
                    
                    metaRow(icon: "camera.viewfinder", title: "Diagonal 1 Photos", value: String(project.diagonal1Photos))
                    metaRow(icon: "camera.viewfinder", title: "Diagonal 2 Photos", value: String(project.diagonal2Photos))
                    if let last = project.lastAnalysisDate {
                        metaRow(icon: "clock.fill", title: "Analyzed", value: last.formatted(.dateTime.month().day().year().hour().minute()))
                    }
                }
            }
            .padding(16)
        }
    }
    
    private func canopyColorFor(_ pct: Double) -> Color {
        switch pct {
        case ..<25: return Color(red: 0.85, green: 0.2, blue: 0.2)     // red
        case 25..<50: return Color.orange                             // orange
        case 50..<75: return Color.yellow                             // yellow
        default: return Color.green                                   // green
        }
    }
    
    private func metaRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 18)
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .glassTextSecondary()
            Spacer(minLength: 8)
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .glassText()
        }
    }
    
    private func weatherPickerRow(project: Project) -> some View {
        HStack(spacing: 10) {
            Image(systemName: weatherIcon(for: project.weatherCondition))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(weatherColor(for: project.weatherCondition))
                .frame(width: 18)
            Text("Weather")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .glassTextSecondary()
            Spacer(minLength: 8)
            Menu {
                weatherOption("Clear", bind: project)
                weatherOption("Partly Cloudy", bind: project)
                weatherOption("Overcast", bind: project)
                weatherOption("Light Rain", bind: project)
                weatherOption("Rain", bind: project)
                weatherOption("Fog", bind: project)
                weatherOption("Snow", bind: project)
                Button("Reset") { project.weatherCondition = nil; try? modelContext.save() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: weatherIcon(for: project.weatherCondition))
                        .foregroundColor(weatherColor(for: project.weatherCondition))
                    Text(project.weatherCondition ?? "Set Weather")
                }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(.white)
            }
            .buttonStyle(.bordered)
        }
    }
    
    private func weatherOption(_ condition: String, bind project: Project) -> some View {
        Button(condition) {
            project.weatherCondition = condition
            try? modelContext.save()
        }
    }
    
    private func weatherIcon(for condition: String?) -> String {
        switch condition {
        case "Clear": return "sun.max.fill"
        case "Partly Cloudy": return "cloud.sun.fill"
        case "Overcast": return "cloud.fill"
        case "Light Rain": return "cloud.drizzle.fill"
        case "Rain": return "cloud.rain.fill"
        case "Fog": return "cloud.fog.fill"
        case "Snow": return "cloud.snow.fill"
        default: return "questionmark.circle"
        }
    }
    
    private func weatherColor(for condition: String?) -> Color {
        switch condition {
        case "Clear": return .yellow
        case "Partly Cloudy": return .orange
        case "Overcast": return .gray
        case "Light Rain": return .blue
        case "Rain": return .blue
        case "Fog": return .gray
        case "Snow": return .white
        default: return .gray
        }
    }
}

#Preview {
    ProjectDataCard(project: Project(name: "Test Project", date: Date(), folderName: "test", location: nil))
        .background(AnimatedForestBackground())
}
