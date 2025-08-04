//
//  LocationModel.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 7/17/25.
//

import Foundation
import CoreLocation

struct Coordinate: Codable, Hashable {
    var latitude: Double
    var longitude: Double
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(from coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
    
    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct LocationModel: Codable, Hashable {
    var center: Coordinate?
    var north: Coordinate?
    var south: Coordinate?
    var northwest: Coordinate?
    var southwest: Coordinate?
    
    init(
        center: Coordinate? = nil,
        north: Coordinate? = nil,
        south: Coordinate? = nil,
        northwest: Coordinate? = nil,
        southwest: Coordinate? = nil) {
            self.center = center
            self.north = north
            self.south = south
            self.northwest = northwest
            self.southwest = southwest
        }
    }
