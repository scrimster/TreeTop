//
//  ProjectPinModel.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 8/3/25.
//

import Foundation
import MapKit

struct ProjectPin: Identifiable {
    let id = UUID()
    let name: String
    let centerCoordinate: CLLocationCoordinate2D
    let diagonalCoordinates: [CLLocationCoordinate2D] // Should have 4 corners
}

extension ProjectPin {
    static let dummyPins: [ProjectPin] = [
        ProjectPin(
            name: "Mock Project Alpha",
            centerCoordinate: CLLocationCoordinate2D(latitude: 41.419, longitude: -72.898),
            diagonalCoordinates: [
                CLLocationCoordinate2D(latitude: 41.4191, longitude: -72.8981),
                CLLocationCoordinate2D(latitude: 41.4191, longitude: -72.8979),
                CLLocationCoordinate2D(latitude: 41.4189, longitude: -72.8979),
                CLLocationCoordinate2D(latitude: 41.4189, longitude: -72.8981),
            ]
        ),
        ProjectPin(
            name: "Mock Project Beta",
            centerCoordinate: CLLocationCoordinate2D(latitude: 41.420, longitude: -72.900),
            diagonalCoordinates: [
                CLLocationCoordinate2D(latitude: 41.4201, longitude: -72.9001),
                CLLocationCoordinate2D(latitude: 41.4201, longitude: -72.8999),
                CLLocationCoordinate2D(latitude: 41.4199, longitude: -72.8999),
                CLLocationCoordinate2D(latitude: 41.4199, longitude: -72.9001),
            ]
        )
    ]
}
