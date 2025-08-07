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
