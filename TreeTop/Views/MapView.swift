//
//  MapView.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 7/31/25.
//

import SwiftUI
import MapKit

struct IdentifiableCoordinate: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct MapScreen: View {
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.4200, longitude: -72.9000),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    
    @State private var selectedPin: ProjectPin? = nil // <-- NEW
    
    let pins = ProjectPin.dummyPins
    
    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            
            // Main project pins
            ForEach(pins) { pin in
                Annotation(pin.name, coordinate: pin.centerCoordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(.red)
                        .onTapGesture {
                            selectedPin = pin
                            print("Tapped on \(pin.name)")
                            
                            cameraPosition = .region(
                                MKCoordinateRegion(
                                    center: pin.centerCoordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
                                )
                            )
                        }
                }
            }
            
            // Diagonal points (debug)
            if let selected = selectedPin {
                let identifiableDiagonals = selected.diagonalCoordinates.map { IdentifiableCoordinate(coordinate: $0) }

                ForEach(identifiableDiagonals) { item in
                    Annotation("corner", coordinate: item.coordinate) {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 10, height: 10)
                    }
                }            }
        }
        .mapStyle(.standard)
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .ignoresSafeArea()
    }
}
