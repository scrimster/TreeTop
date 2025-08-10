//
//  LocationManagerTests.swift
//  TreeTopTests
//
//  Created by Lesly Reinoso on 8/1/25.
//

import XCTest
import CoreLocation
import Combine
import ImageIO
@testable import TreeTop

final class LocationManagerTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }



    func test_authorizationStatus_isPublishedOnDelegateChange() {
        let sut = LocationManager()

        let exp = expectation(description: "authorizationStatus published")
        sut.$authorizationStatus
            .dropFirst()
            .sink { status in
                XCTAssertEqual(status, .authorizedWhenInUse)
                exp.fulfill()
            }
            .store(in: &cancellables)

        sut.locationManager(CLLocationManager(), didChangeAuthorization: .authorizedWhenInUse)
        wait(for: [exp], timeout: 1.0)
    }



    func test_didUpdateLocations_setsCurrentLocation_andPublishes() throws {
        let sut = LocationManager()
        let sample = CLLocation(latitude: 41.3083, longitude: -72.9279)

        let exp = expectation(description: "currentLocation published")
        var captured: CLLocation?
        sut.$currentLocation
            .dropFirst()
            .sink { loc in captured = loc; exp.fulfill() }
            .store(in: &cancellables)

        sut.locationManager(CLLocationManager(), didUpdateLocations: [sample])
        wait(for: [exp], timeout: 1.0)

        let unwrapped = try XCTUnwrap(captured, "currentLocation should not be nil")
        XCTAssertEqual(unwrapped.coordinate.latitude,  sample.coordinate.latitude,  accuracy: 1e-6)
        XCTAssertEqual(unwrapped.coordinate.longitude, sample.coordinate.longitude, accuracy: 1e-6)
    }



    func test_requestLocation_completionCalledOnce_thenCleared() {
        let sut = LocationManager()
        let sample = CLLocation(latitude: 34.0522, longitude: -118.2437)

        var calls = 0
        let exp = expectation(description: "completion called")
        sut.requestLocation { loc in
            calls += 1
            guard let loc = loc else {
                XCTFail("Expected non-nil location")
                return
            }
            XCTAssertEqual(loc.coordinate.latitude,  sample.coordinate.latitude,  accuracy: 1e-6)
            XCTAssertEqual(loc.coordinate.longitude, sample.coordinate.longitude, accuracy: 1e-6)
            exp.fulfill()
        }

        // First update triggers completion
        sut.locationManager(CLLocationManager(), didUpdateLocations: [sample])
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(calls, 1)

        // Second update should NOT call completion again (it’s cleared)
        sut.locationManager(CLLocationManager(), didUpdateLocations: [sample])
        XCTAssertEqual(calls, 1)
    }



    func test_didFailWithError_doesNotChangeCurrentLocation() {
        let sut = LocationManager()
        XCTAssertNil(sut.currentLocation)

        sut.locationManager(CLLocationManager(), didFailWithError: NSError(domain: "Test", code: -1))

        XCTAssertNil(sut.currentLocation)
    }



    func test_toGPSMetadata_includesExpectedKeys_andCorrectRefs() {
        // Southern (S) & Western (W), negative altitude -> AltitudeRef = 1
        let validCoord = CLLocationCoordinate2D(latitude: -33.8688, longitude: -151.2093)

        var comps = DateComponents()
        comps.year = 2024; comps.month = 1; comps.day = 5
        comps.hour = 12; comps.minute = 34; comps.second = 56
        comps.nanosecond = 123_456_000
        comps.timeZone = TimeZone(secondsFromGMT: 0)
        let date = Calendar(identifier: .gregorian).date(from: comps)!

        let loc = CLLocation(coordinate: validCoord,
                             altitude: -25.0,
                             horizontalAccuracy: 5,
                             verticalAccuracy: 5,
                             timestamp: date)

        let meta = loc.toGPSMetadata()
        guard let gps = meta[kCGImagePropertyGPSDictionary] as? [CFString: Any] else {
            return XCTFail("Expected GPS dictionary")
        }

        XCTAssertNotNil(gps[kCGImagePropertyGPSLatitude])
        XCTAssertNotNil(gps[kCGImagePropertyGPSLatitudeRef])
        XCTAssertNotNil(gps[kCGImagePropertyGPSLongitude])
        XCTAssertNotNil(gps[kCGImagePropertyGPSLongitudeRef])
        XCTAssertNotNil(gps[kCGImagePropertyGPSAltitude])
        XCTAssertNotNil(gps[kCGImagePropertyGPSAltitudeRef])
        XCTAssertNotNil(gps[kCGImagePropertyGPSTimeStamp])
        XCTAssertNotNil(gps[kCGImagePropertyGPSDateStamp])

        XCTAssertEqual(gps[kCGImagePropertyGPSLatitudeRef] as? String, "S")
        XCTAssertEqual(gps[kCGImagePropertyGPSLongitudeRef] as? String, "W")
        XCTAssertGreaterThan((gps[kCGImagePropertyGPSLatitude]  as? Double) ?? -1, 0)
        XCTAssertGreaterThan((gps[kCGImagePropertyGPSLongitude] as? Double) ?? -1, 0)
        XCTAssertEqual(gps[kCGImagePropertyGPSAltitudeRef] as? Int, 1)

        XCTAssertEqual(DateFormatter.gpsDateFormatter.string(from: date), "2024:01:05")
        XCTAssertTrue(DateFormatter.gpsTimeFormatter.string(from: date).hasPrefix("12:34:56"))
    }
}
