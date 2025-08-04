//
//  PhotoCoordinates.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 8/2/25.
//

import Foundation
import CoreLocation
import ImageIO

struct ImageMDReader {
    //set-up function to access GPS metadata
    static func extract(from url: URL) -> Coordinate? {
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let gps = metadata[kCGImagePropertyGPSDictionary] as? [CFString: Any]

        else {
            print("Failed to extract GPS metadata from: \(url.lastPathComponent)")
            return nil
        }

        guard
            let latitude = gps[kCGImagePropertyGPSLatitude] as? Double,
            let latitudeRef = gps[kCGImagePropertyGPSLatitudeRef] as? String,
            let longitude = gps[kCGImagePropertyGPSLongitude] as? Double,
            let longitudeRef = gps[kCGImagePropertyGPSLongitudeRef] as? String
        else {
            print("Missing GPS Coordinates in metadata from: \(url.lastPathComponent)")
            return nil
        }
        
        let lat = (latitudeRef == "S") ? -latitude : latitude
        let lon = (longitudeRef == "W") ? -longitude : longitude

        print("📸 Extracted GPS: (\(lat), \(lon)) from: \(url.lastPathComponent)")
        return Coordinate(latitude: lat, longitude: lon)
    }
}
