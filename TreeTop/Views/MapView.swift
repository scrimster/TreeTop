//
//  MapView.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 7/31/25.
//

import SwiftUI
import MapKit

struct MapScreen: View {
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.4200, longitude: -72.9000),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    
    var body: some View {
        Map(position: $cameraPosition)
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .ignoresSafeArea()
    }
}

#Preview {
    MapScreen()
}
