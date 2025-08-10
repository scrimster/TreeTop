//
//  ProjectSheetView.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 8/7/25.
//

import SwiftUI
import CoreLocation
import MapKit

struct ProjectSheetView: View {
    private let contentWidth: CGFloat = 560
    private let thumbSize: CGFloat = 60
    private let rowGap: CGFloat = 12
    private let rowHPad: CGFloat = 8
    private var textIndent: CGFloat { thumbSize + rowGap }

    @State private var searchText: String = ""

    let projects: [Project]
    @Binding var selectedProject: Project?
    var onSelect: ((Project) -> Void)? = nil

    // Newest first
    var sortedProjects: [Project] {
        projects.sorted { $0.date > $1.date }
    }

    // Search by name
    var filteredProjects: [Project] {
        if searchText.isEmpty {
            return sortedProjects
        } else {
            return sortedProjects.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        LiquidGlassCard(cornerRadius: 20) {
            VStack(spacing: 16) {

                // Title
                Text("Your Projects")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)

                // Search
                HStack {
                    Spacer()
                    TextField("Search projects...", text: $searchText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .liquidGlass(cornerRadius: 12, strokeOpacity: 0.18, shadowRadius: 0)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .frame(maxWidth: contentWidth)
                    Spacer()
                }
                .padding(.horizontal)

                // Project list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredProjects, id: \.self) { project in
                            ProjectRow(
                                project: project,
                                isSelected: selectedProject?.id == project.id,
                                onSelect: { p in onSelect?(p) }
                            )
                            .frame(maxWidth: contentWidth, alignment: .center)
                        }
                    }
                    .frame(maxWidth: .infinity) // centers stack in the sheet
                    .padding(.vertical, 8)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.bottom, 12)
            .padding(.horizontal)
        }
        .padding() // shows the rounded glass edges inside the sheet
    }

}

// MARK: - Row

private struct ProjectRow: View {
    let project: Project
    let isSelected: Bool
    var onSelect: (Project) -> Void

    @State private var placeText: String = ""

    var body: some View {
        let active = isSelected

        Button {
            onSelect(project)
        } label: {
            HStack(spacing: 12) {
                // Thumbnail or placeholder (cached)
                if let image = cachedCenterThumbnail(for: project) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .clipped()
                        .opacity(active ? 0.85 : 1.0) // dim slightly when selected
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .overlay(Image(systemName: "photo").foregroundColor(.gray))
                        .opacity(active ? 0.85 : 1.0)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(active ? .white : .primary)

                    if !placeText.isEmpty {
                        Text(placeText)
                            .font(.caption)
                            .foregroundStyle(active ? .white.opacity(0.9) : .secondary.opacity(0.95))
                    }

                    Text("Created: \(project.date.formatted(.dateTime.month().day().year()))")
                        .font(.caption)
                        .foregroundStyle(active ? .white.opacity(0.9) : .secondary.opacity(0.95))
                }

                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(active ? Color.blue.opacity(0.35) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(active ? 0.28 : 0.12), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .task {
            if let coord = project.centerCoordinate {
                ReverseGeoCache.shared.placename(for: coord) { text in
                    placeText = text
                }
            }
        }
    }
}
// Cache-aware thumbnail resolver for list rows
private func cachedCenterThumbnail(for project: Project) -> UIImage? {
    // Build a stable key from file path(s)
    let thumbPath = project.centerReferenceThumbnailURL()?.path
    let fullPath  = project.centerReferenceImageURL()?.path
    let key = thumbPath ?? fullPath ?? "project-\(String(describing: project.id))"

    // 1) Memory cache
    if let cached = ImageCache.shared.image(forKey: key) {
        return cached
    }

    // 2) ProjectManager check
    if let img = ProjectManager.shared.getCenterReferenceThumbnail(for: project) {
        ImageCache.shared.set(img, forKey: key, cost: imgCost(img))
        return img
    }

    // 3) Fallback to disk URLs if needed
    if let path = thumbPath, FileManager.default.fileExists(atPath: path),
       let img = UIImage(contentsOfFile: path) {
        ImageCache.shared.set(img, forKey: key, cost: imgCost(img))
        return img
    }
    if let path = fullPath, FileManager.default.fileExists(atPath: path),
       let img = UIImage(contentsOfFile: path) {
        ImageCache.shared.set(img, forKey: key, cost: imgCost(img))
        return img
    }

    return nil
}

private func imgCost(_ image: UIImage) -> Int {
    let px = Int(image.size.width * image.size.height * max(image.scale, 1))
    return px * 4
}



// MARK: - Reverse geocode cache

final class ReverseGeoCache {
    static let shared = ReverseGeoCache()
    private let geocoder = CLGeocoder()
    private let cache = NSCache<NSString, NSString>()

    func placename(for coordinate: CLLocationCoordinate2D, completion: @escaping (String) -> Void) {
        let key = NSString(string: String(format: "%.5f,%.5f", coordinate.latitude, coordinate.longitude))
        if let cached = cache.object(forKey: key) {
            completion(cached as String)
            return
        }

        let loc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(loc) { placemarks, _ in
            let p = placemarks?.first

            let city = p?.locality
            let state = p?.administrativeArea
            let iso = p?.isoCountryCode
            let country = p?.country

            // Format “City, ST, USA” if US; else City, Region, Country
            let countryDisplay: String? = {
                if iso?.uppercased() == "US" { return "USA" }
                return iso ?? country
            }()

            let pieces = [city, state, countryDisplay].compactMap { $0 }.joined(separator: ", ")
            let result = pieces.isEmpty ? "—" : pieces

            self.cache.setObject(NSString(string: result), forKey: key)
            completion(result)
        }
    }
}

struct ProjectInfoSheet: View {
    let project: Project

    private let metricCols: [GridItem] = [
        GridItem(.flexible(minimum: 150), spacing: 12),
        GridItem(.flexible(minimum: 150), spacing: 12)
    ]
    
    var onOpenProject: () -> Void
    var onDirections: () -> Void

    var body: some View {
        ScrollView {
            LiquidGlassCard(cornerRadius: 20) {
                VStack(alignment: .leading, spacing: 16) {

                    // HEADER
                    HStack(spacing: 12) {
                        if let thumb = sheetThumbnail(for: project) {
                            Image(uiImage: thumb)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12).fill(.gray.opacity(0.18))
                                Image(systemName: "camera")
                            }
                            .frame(width: 64, height: 64)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(project.name)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.primary)

                            Text(project.date.formatted(.dateTime.month().day().year()))
                                .font(.subheadline)
                                .foregroundStyle(.primary.opacity(0.9))
                                .lineLimit(1)
                        }
                        Spacer()
                    }

                    // METRICS (grid layout)
                    LazyVGrid(columns: metricCols, spacing: 12) {
                        if let coord = project.centerCoordinate {
                            MetricPill(
                                title: "Coordinates",
                                value: String(format: "%.5f, %.5f", coord.latitude, coord.longitude)
                            )
                            .contextMenu {
                                Button("Copy Coordinates") {
                                    UIPasteboard.general.string = String(
                                        format: "%.5f, %.5f",
                                        coord.latitude, coord.longitude
                                    )
                                }
                                Button("Open in Maps") {
                                    let item = MKMapItem(placemark: MKPlacemark(coordinate: coord))
                                    item.name = project.name
                                    item.openInMaps()
                                }
                            }
                        } else {
                            MetricPill(title: "Coordinates", value: "—")
                        }
                        
                        MetricPill(
                            title: "Canopy",
                            value: {
                                if let c = project.canopyCoverPercentage {
                                    return String(format: "%.1f%%", c)
                                } else { return "—" }
                            }()
                        )
                        
                        MetricPill(
                            title: "Last analyzed",
                            value: project.lastAnalysisDate?
                                .formatted(.dateTime.month().day().year().hour().minute()) ?? "—"
                        )
                        
                        MetricPill(
                            title: "Elevation",
                            value: String(format: "%.1f m", project.elevation)   // meters
                        )
                    }

                    // ACTIONS
                    HStack(spacing: 12) {
                        Button(action: onOpenProject) {
                            Label("Open Project", systemImage: "folder")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button(action: onDirections) {
                            Label("Directions", systemImage: "car.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .padding()
        }
        .scrollIndicators(.hidden)
    }

}

private struct MetricPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.footnote.weight(.semibold))
                .tracking(0.3)
                .foregroundStyle(.primary.opacity(0.85))

            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.clear))
        .modifier(LiquidGlassStyle(cornerRadius: 12, strokeOpacity: 0.26, shadowRadius: 0))
    }
}

// Local, cache-aware thumbnail loader so this view is self-contained
private func sheetThumbnail(for project: Project) -> UIImage? {
    let thumbPath = project.centerReferenceThumbnailURL()?.path
    let fullPath  = project.centerReferenceImageURL()?.path
    let key = thumbPath ?? fullPath ?? "project-\(String(describing: project.id))"

    if let cached = ImageCache.shared.image(forKey: key) {
        return cached
    }
    if let p = thumbPath, FileManager.default.fileExists(atPath: p),
       let img = UIImage(contentsOfFile: p) {
        ImageCache.shared.set(img, forKey: key, cost: imgCost(img))
        return img
    }
    if let p = fullPath, FileManager.default.fileExists(atPath: p),
       let img = UIImage(contentsOfFile: p) {
        ImageCache.shared.set(img, forKey: key, cost: imgCost(img))
        return img
    }
    return nil
}

