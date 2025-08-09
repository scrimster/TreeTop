//
//  MapView.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 7/31/25.
//

import SwiftUI
import MapKit
import SwiftData

struct MapScreen: View {
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showProjectSheet = false
    @State private var selectedProjectFromMap: Project? = nil

    @Query var projects: [Project]

    // Only show projects with a valid center coordinate
    var validPins: [Project] {
        projects.filter { $0.centerCoordinate != nil }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { geometry in
                Map(position: $cameraPosition) {
                    UserAnnotation()

                    ForEach(validPins, id: \.self) { project in
                        if let coordinate = project.centerCoordinate {
                            Annotation(project.name, coordinate: coordinate) {
                                Image(systemName: "mappin.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(.red)
                                    .onTapGesture {
                                        zoomTo(project: project)
                                        selectedProjectFromMap = project
                                    }
                                    .onAppear {
                                        print("📍 Rendering pin for project: \(project.name) at \(coordinate.latitude), \(coordinate.longitude)")
                                    }
                            }
                        }
                    }
                }
                .mapStyle(.standard)
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }

            // Floating folder button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showProjectSheet = true
                    }) {
                        Image(systemName: "folder")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            showProjectSheet = true

            if let userLocation = LocationManager.shared.currentLocation {
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
        .sheet(isPresented: $showProjectSheet) {
            ProjectSheetView(
                projects: projects,
                selectedProject: $selectedProjectFromMap,
                onSelect: { selected in
                    selectedProjectFromMap = selected
                    zoomTo(project: selected)
                }
            )
            .presentationDetents([.fraction(0.2), .medium, .large])
        }
        .navigationBarBackButtonHidden(false)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

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
}
