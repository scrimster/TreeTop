//
//  MapView.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 7/31/25.
//

import SwiftUI
import MapKit
import SwiftData
import CoreLocation

struct MapScreen: View {
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showProjectSheet = false
    @State private var selectedProjectFromMap: Project? = nil
    @State private var currentLatDelta: CLLocationDegrees = 0.01
    @State private var didAutoFitAllPins = false
    @State private var sheetDetent: PresentationDetent = .fraction(0.4)
    @State private var lastRegion: MKCoordinateRegion?
    @State private var navToProject: Project? = nil
    @State private var infoProject: Project? = nil
    
    private var sheetBG: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.24, blue: 0.52),
                Color(red: 0.05, green: 0.65, blue: 0.45)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
   
    private struct Cluster: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
        let members: [Project]
    }

    @Query var projects: [Project]

    // Only show projects with a valid center coordinate
    var validPins: [Project] {
        projects.filter { $0.centerCoordinate != nil }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { _ in
                ZStack {
                    Map(position: $cameraPosition) {
                        UserAnnotation()

                        ForEach(clusteredPins) { cluster in
                            if cluster.members.count == 1,
                               let project = cluster.members.first,
                               let coord = project.centerCoordinate {
                                Annotation("", coordinate: coord, anchor: .bottom) {
                                    projectPinView(for: project)
                                }
                            } else {
                                Annotation("", coordinate: cluster.coordinate, anchor: .center) {
                                    Button { zoomInto(cluster: cluster) } label: {
                                        ZStack {
                                            Circle()
                                                .fill(Color.clear)
                                                .frame(width: 36, height: 36)
                                                .modifier(LiquidGlassCircleStyle(strokeOpacity: 0.25, shadowRadius: 6))
                                            Text("\(cluster.members.count)")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.primary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .onMapCameraChange(frequency: .continuous) { context in
                        currentLatDelta = context.region.span.latitudeDelta
                        lastRegion = context.region
                    }
                    .mapStyle(.standard)
                    .ignoresSafeArea()

                    sheetBG
                        .opacity(0.15)
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }
            }

            // Floating actions (Fit All, Recenter, Folder)
            VStack {
                Spacer()
                HStack {
                    Spacer()

                    VStack(spacing: 12) {
                        // Fit all pins
                        Button(action: { fitAllProjectPins() }) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                                .padding(12)
                                .background(Circle().fill(Color.clear))
                                .modifier(LiquidGlassCircleStyle(strokeOpacity: 0.25, shadowRadius: 6))
                        }

                        // Recenter to user
                        Button(action: { recenterToUser() }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                                .padding(12)
                                .background(Circle().fill(Color.clear))
                                .modifier(LiquidGlassCircleStyle(strokeOpacity: 0.25, shadowRadius: 6))
                        }

                        // Folder (open sheet)
                        Button(action: {
                            showProjectSheet = true
                        }) {
                            Image(systemName: "folder")
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                                .padding(12)
                                .background(Circle().fill(Color.clear))
                                .modifier(LiquidGlassCircleStyle(strokeOpacity: 0.25, shadowRadius: 6))
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            showProjectSheet = true

            if !didAutoFitAllPins, !validPins.isEmpty {
                fitAllProjectPins()
                didAutoFitAllPins = true
            } else if let userLocation = LocationManager.shared.currentLocation {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: userLocation.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )
            } else {
                print("⚠️ User location not available")
            }
        }
        .onChange(of: projects) {
            if !didAutoFitAllPins, !validPins.isEmpty {
                fitAllProjectPins()
                didAutoFitAllPins = true
            }
        }
        // Project picker sheet
        .sheet(isPresented: $showProjectSheet) {
            ProjectSheetView(
                projects: projects,
                selectedProject: $selectedProjectFromMap,
                onSelect: { selected in
                    selectedProjectFromMap = selected
                    withAnimation { showProjectSheet = false }
                    zoomTightTo(selected)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { infoProject = selected }
                }
            )
            .presentationDetents([.fraction(0.4), .medium, .large], selection: $sheetDetent)
            .presentationBackground(sheetBG)
        }
        .navigationBarBackButtonHidden(false)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        // Info sheet
        .sheet(item: $infoProject) { project in
            ProjectInfoSheet(
                project: project,
                onOpenProject: { infoProject = nil; navToProject = project },
                onDirections: { openDirections(to: project) }
            )
            .presentationDragIndicator(.visible)
            .presentationDetents([.fraction(0.35), .medium, .large])
            .presentationBackground(sheetBG)
            .presentationBackgroundInteraction(.enabled)
        }
        .navigationDestination(item: $navToProject) { project in
            FolderContentsView(folderURL: project.folderURL, project: project)
        }


    }

    @ViewBuilder
    private func projectPinView(for project: Project) -> some View {
        VStack(spacing: 6) {

            // Tappable pin
            Button {
                zoomTightTo(project)
                infoProject = project
                print("🔺 Open sheet for: \(project.name)")
            } label: {
                ZStack {
                    // bigger hit target (keeps pin easy to tap)
                    Circle().fill(Color.clear).frame(width: 44, height: 44).contentShape(Circle())
                    Image(systemName: "mappin.circle.fill")
                        .symbolRenderingMode(.monochrome)
                        .foregroundColor(.red)
                        .font(.system(size: pinSize(for: currentLatDelta)))
                }
            }
            .buttonStyle(.plain)
        }
    }


    // MARK: - Actions / helpers

    // Zoom in to center reference coordinate only
    func zoomTo(project: Project) {
        guard let coordinate = project.centerCoordinate else {
            print("⚠️ Project '\(project.name)' has no saved coordinates.")
            return
        }

        cameraPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
            )
        )

        print("🔍 Zoomed to project: \(project.name)")
    }

    // Pin scales with zoom
    private func pinSize(for latDelta: CLLocationDegrees) -> CGFloat {
        let minDelta: CLLocationDegrees = 0.002
        let maxDelta: CLLocationDegrees = 0.20
        let minSize: CGFloat = 22
        let maxSize: CGFloat = 48

        let clamped = max(minDelta, min(latDelta, maxDelta))
        let t = (clamped - minDelta) / (maxDelta - minDelta)
        return maxSize - (maxSize - minSize) * CGFloat(t)
    }

    // Recenter to the user's current location
    private func recenterToUser() {
        if let userLocation = LocationManager.shared.currentLocation {
            withAnimation(.easeInOut(duration: 0.25)) {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: userLocation.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )
            }
        } else {
            print("⚠️ User location not available")
        }
    }

    // Fit all pins on screen
    private func fitAllProjectPins(pad factor: Double = 1.3, animated: Bool = true) {
        let coords = validPins.compactMap { $0.centerCoordinate }
        guard !coords.isEmpty else { return }

        var rect = MKMapRect.null
        for c in coords {
            let p = MKMapPoint(c)
            rect = rect.union(MKMapRect(x: p.x, y: p.y, width: 0.01, height: 0.01))
        }

        var region = MKCoordinateRegion(rect)
        region.span.latitudeDelta  *= factor
        region.span.longitudeDelta *= factor

        if animated {
            withAnimation(.easeInOut(duration: 0.25)) {
                cameraPosition = .region(region)
            }
        } else {
            cameraPosition = .region(region)
        }
    }

    // Open Apple Maps with directions to the project's center coordinate
    private func openDirections(to project: Project,
                                mode: String = MKLaunchOptionsDirectionsModeDriving) {
        guard let coord = project.centerCoordinate else { return }

        let dest = MKMapItem(placemark: MKPlacemark(coordinate: coord))
        dest.name = project.name

        let launchOptions: [String: Any] = [
            MKLaunchOptionsDirectionsModeKey: mode,
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: coord),
            MKLaunchOptionsMapSpanKey: NSValue(
                mkCoordinateSpan: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        ]
        MKMapItem.openMaps(with: [dest], launchOptions: launchOptions)
    }
    
    // Make grid clusters based on current zoom level (latDelta)
    private func makeClusters(projects: [Project], latDelta: CLLocationDegrees) -> [Cluster] {
        guard !projects.isEmpty else { return [] }

        // cell size grows with zoomed-out views; tweak the multiplier to taste
        let cellSize = max(0.01, latDelta * 0.6) // ~0.6x the current span

        var buckets: [String: [Project]] = [:]

        func bucketKey(for c: CLLocationCoordinate2D) -> String {
            let latBucket = Int(floor(c.latitude  / cellSize))
            let lonBucket = Int(floor(c.longitude / cellSize))
            return "\(latBucket)_\(lonBucket)"
        }

        for p in projects {
            guard let c = p.centerCoordinate else { continue }
            buckets[bucketKey(for: c), default: []].append(p)
        }

        // Convert buckets into clusters at the average coordinate
        var clusters: [Cluster] = []
        clusters.reserveCapacity(buckets.count)
        for (_, group) in buckets {
            let coords = group.compactMap { $0.centerCoordinate }
            let avgLat = coords.map(\.latitude).reduce(0, +) / Double(coords.count)
            let avgLon = coords.map(\.longitude).reduce(0, +) / Double(coords.count)
            clusters.append(Cluster(coordinate: .init(latitude: avgLat, longitude: avgLon), members: group))
        }
        return clusters
    }

    private var clusteredPins: [Cluster] {
        // Use your filtered list that already guarantees coordinates
        makeClusters(projects: validPins, latDelta: currentLatDelta)
    }

    // Zoom into a cluster to "split" it
    private func zoomInto(cluster: Cluster) {
        let coords = cluster.members.compactMap { $0.centerCoordinate }
        guard !coords.isEmpty else { return }

        var rect = MKMapRect.null
        for c in coords {
            let p = MKMapPoint(c)
            rect = rect.union(MKMapRect(x: p.x, y: p.y, width: 0.01, height: 0.01))
        }
        var region = MKCoordinateRegion(rect)
        // tighten a bit so we zoom in more than fitAll
        region.span.latitudeDelta  *= 0.6
        region.span.longitudeDelta *= 0.6

        withAnimation(.easeInOut(duration: 0.25)) {
            cameraPosition = .region(region)
        }
    }

    private func zoomTightTo(_ project: Project,
                             latDelta: CLLocationDegrees = 0.0006,
                             lonDelta: CLLocationDegrees = 0.0006,
                             animated: Bool = true) {
        guard let c = project.centerCoordinate else { return }
        let region = MKCoordinateRegion(
            center: c,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
        if animated {
            withAnimation(.easeInOut(duration: 0.30)) {
                cameraPosition = .region(region)
            }
        } else {
            cameraPosition = .region(region)
        }
    }
}
