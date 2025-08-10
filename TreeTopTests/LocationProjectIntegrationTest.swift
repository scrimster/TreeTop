//
//  LocationProjectIntegrationTest.swift
//  TreeTopTests
//
//  Created by Lesly Reinoso on 8/10/25.
//

import XCTest
import SwiftData
import CoreLocation
@testable import TreeTop

// Test-only helper: update numeric coords on Project via ProjectManager
private extension ProjectManager {
    func updateProject(_ project: Project, with location: CLLocation, elevation: Double? = nil) {
        project.latitude  = location.coordinate.latitude
        project.longitude = location.coordinate.longitude
        project.elevation = elevation ?? location.altitude
        // Note: we intentionally DO NOT set `project.location` here because it's a `LocationModel`, not a String.
        try? modelContext.save()
    }
}

final class LocationProjectIntegrationTests: XCTestCase {



    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([Project.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [cfg])
        return ModelContext(container)
    }



    func test_oneShotLocation_updatesProjectCoordinates_viaProjectManager() throws {
        // Arrange
        let ctx = try makeInMemoryContext()
        let projectManager = ProjectManager(modelContext: ctx)
        let project = try XCTUnwrap(projectManager.createProject(name: "Loc→Proj", date: .now))
        let locationManager = LocationManager()

        // Start values
        XCTAssertEqual(project.latitude,  0.0, accuracy: 1e-9)
        XCTAssertEqual(project.longitude, 0.0, accuracy: 1e-9)

        // Request a one-shot location
        let expected = CLLocation(latitude: 37.7749, longitude: -122.4194) // SF
        var completed: CLLocation?
        let exp = expectation(description: "location completion")

        locationManager.requestLocation { loc in
            completed = loc
            exp.fulfill()
        }
        // Simulate Core Location delivering the update
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [expected])
        wait(for: [exp], timeout: 1.0)

        // Update project with that location
        let loc = try XCTUnwrap(completed)
        projectManager.updateProject(project, with: loc)

        // Assert: numeric coordinates & elevation persisted
        XCTAssertEqual(project.latitude,  expected.coordinate.latitude,  accuracy: 1e-6)
        XCTAssertEqual(project.longitude, expected.coordinate.longitude, accuracy: 1e-6)
        XCTAssertEqual(project.elevation, loc.altitude, accuracy: 1e-6)
    }

    func test_multipleLocationUpdates_onlyFirstCompletionUsed_projectRemainsFirstLocation() throws {
        let ctx = try makeInMemoryContext()
        let projectManager = ProjectManager(modelContext: ctx)
        let project = try XCTUnwrap(projectManager.createProject(name: "FirstWins", date: .now))
        let locationManager = LocationManager()

        let first  = CLLocation(latitude: 40.7128,  longitude: -74.0060)   // NYC
        let second = CLLocation(latitude: 34.0522,  longitude: -118.2437)  // LA

        var completed: CLLocation?
        let exp = expectation(description: "location completion")
        locationManager.requestLocation { loc in
            completed = loc
            exp.fulfill()
        }

        // Deliver two updates; completion should be called only once (on the first)
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [first])
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [second])
        wait(for: [exp], timeout: 1.0)

        let loc = try XCTUnwrap(completed)
        projectManager.updateProject(project, with: loc)

        XCTAssertEqual(project.latitude,  first.coordinate.latitude,  accuracy: 1e-6)
        XCTAssertEqual(project.longitude, first.coordinate.longitude, accuracy: 1e-6)
    }
}
