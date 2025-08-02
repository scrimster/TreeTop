//
//  PhotoCoordinates.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 8/2/25.
//

import Foundation
import CoreLocation
import ImageIO

struct PhotoCoordinates {
    //set-up function to access GPS metadata
    static func extract(from url: URL) ->CLLocationCoordinate2D? {
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let gps = metadata[kCGImagePropertyGPSDictionary] as? [CFString: Any]
        else {
            return nil
        }
        guard
            let latitude = gps[kCGImagePropertyGPSLatitude] as? Double,
            let latitudeRef = gps[kCGImagePropertyGPSLatitudeRef] as? String,
            let longitude = gps[kCGImagePropertyGPSLongitude] as? Double,
            let longitudeRef = gps[kCGImagePropertyGPSLongitudeRef] as? String
        else {
            return nil
        }
        
        let lat = (latitudeRef == "S") ? -latitude : latitude
        let lon = (longitudeRef == "W") ? -longitude : longitude
        
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
