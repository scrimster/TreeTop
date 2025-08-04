//
//  LocationManager.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 7/17/25.
//

import Foundation
import CoreLocation
import Combine
import ImageIO

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    private var completionHandler: ((CLLocation?) -> Void)?
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        // Don't start updating location here - wait for authorization
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            break // Silently handle denied access
        case .notDetermined:
            break // Waiting for user decision
        @unknown default:
            break // Handle unknown future cases
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
            currentLocation = lastLocation
            completionHandler?(lastLocation)
            completionHandler = nil
        }
    }

    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silently handle location errors to avoid console spam
        completionHandler?(nil)
        completionHandler = nil
    }
    
    func requestLocationOnce(completion: @escaping (CLLocation?) -> Void) {
        let tempManager = CLLocationManager()
        tempManager.desiredAccuracy = kCLLocationAccuracyBest

        let delegate = LocationRequestDelegate(completion: completion)
        tempManager.delegate = delegate

        // Store the delegate so it doesn't get deallocated immediately
        objc_setAssociatedObject(tempManager, "[\(UUID())]", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        tempManager.requestWhenInUseAuthorization()
        tempManager.requestLocation()
    }
    
    func requestLocation(completion: @escaping (CLLocation?) -> Void) {
        self.completionHandler = completion
        manager.requestLocation()
    }

}

private class LocationRequestDelegate: NSObject, CLLocationManagerDelegate {
    private let completion: (CLLocation?) -> Void

    init(completion: @escaping (CLLocation?) -> Void) {
        self.completion = completion
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        completion(locations.last)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Failed to get location: \(error)")
        completion(nil)
    }
}

extension CLLocation {
    func toGPSMetadata() -> [CFString: Any] {
        var gps: [CFString: Any] = [:]

        let altitudeRef = self.altitude < 0.0 ? 1 : 0
        let latitudeRef = self.coordinate.latitude < 0.0 ? "S" : "N"
        let longitudeRef = self.coordinate.longitude < 0.0 ? "W" : "E"

        gps[kCGImagePropertyGPSLatitude] = abs(self.coordinate.latitude)
        gps[kCGImagePropertyGPSLatitudeRef] = latitudeRef
        gps[kCGImagePropertyGPSLongitude] = abs(self.coordinate.longitude)
        gps[kCGImagePropertyGPSLongitudeRef] = longitudeRef
        gps[kCGImagePropertyGPSAltitude] = abs(self.altitude)
        gps[kCGImagePropertyGPSAltitudeRef] = altitudeRef
        gps[kCGImagePropertyGPSTimeStamp] = DateFormatter.gpsTimeFormatter.string(from: self.timestamp)
        gps[kCGImagePropertyGPSDateStamp] = DateFormatter.gpsDateFormatter.string(from: self.timestamp)

        return [kCGImagePropertyGPSDictionary: gps]
    }
}

extension DateFormatter {
    static let gpsDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()

    static let gpsTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSSSSS"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
}

