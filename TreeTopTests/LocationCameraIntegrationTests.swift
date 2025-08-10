//
//  LocationCameraIntegrationTests.swift
//  TreeTopTests
//
//  Created by Lesly Reinoso on 8/7/25.
//

import XCTest
import CoreLocation
import UIKit
import Combine
import ImageIO
@testable import TreeTop

final class LocationCameraIntegrationTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    // Simple synthetic image so the test is self‑contained
    private func makeTestImage(size: CGSize = .init(width: 256, height: 256)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor.black.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height/2))
        }
    }

    func test_requestLocation_thenCaptureImage_flow_succeeds_andGPSMetadataBuilds() throws {
        // Arrange
        let locationManager = LocationManager()
        let camera = CameraManager()
        let expected = CLLocation(latitude: 40.7128, longitude: -74.0060) // NYC

        // 1) Request a one‑shot location
        var completionLoc: CLLocation?
        let locExp = expectation(description: "location completion called")
        locationManager.requestLocation { loc in
            completionLoc = loc
            locExp.fulfill()
        }

        // Simulate Core Location delivering the update
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [expected])

        wait(for: [locExp], timeout: 1.0)

        // Assert location arrived (unwrap to get non-optional)
        let loc = try XCTUnwrap(completionLoc, "Expected a non‑nil location from requestLocation completion")
        XCTAssertEqual(loc.coordinate.latitude,  expected.coordinate.latitude,  accuracy: 1e-6)
        XCTAssertEqual(loc.coordinate.longitude, expected.coordinate.longitude, accuracy: 1e-6)

        // 2) “Capture” an image via CameraManager (just append)
        let image = makeTestImage()
        camera.capturedImage.append(image)
        XCTAssertEqual(camera.capturedImage.count, 1, "CameraManager should hold the captured image")

        // 3) Build GPS metadata from that location ( when saving)
        let gps = loc.toGPSMetadata()
        guard let gpsDict = gps[kCGImagePropertyGPSDictionary] as? [CFString: Any] else {
            return XCTFail("Expected GPS dictionary in metadata")
        }
        XCTAssertNotNil(gpsDict[kCGImagePropertyGPSLatitude])
        XCTAssertNotNil(gpsDict[kCGImagePropertyGPSLongitude])
        XCTAssertEqual(gpsDict[kCGImagePropertyGPSLatitudeRef] as? String, "N")
        XCTAssertEqual(gpsDict[kCGImagePropertyGPSLongitudeRef] as? String, "W")
    }

    func test_locationDelegate_alsoPublishesCurrentLocation_forObservers() throws {
        let locationManager = LocationManager()
        let pubExp = expectation(description: "currentLocation published")

        var published: CLLocation?
        locationManager.$currentLocation
            .dropFirst() // skip initial nil
            .sink { loc in
                published = loc
                pubExp.fulfill()
            }
            .store(in: &cancellables)

        let sample = CLLocation(latitude: 34.0522, longitude: -118.2437) // LA
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [sample])

        wait(for: [pubExp], timeout: 1.0)

        let unwrapped = try XCTUnwrap(published, "currentLocation should publish a non‑nil value")
        XCTAssertEqual(unwrapped.coordinate.latitude,  sample.coordinate.latitude,  accuracy: 1e-6)
        XCTAssertEqual(unwrapped.coordinate.longitude, sample.coordinate.longitude, accuracy: 1e-6)
    }
}
