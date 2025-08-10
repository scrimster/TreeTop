//
//  CameraSummaryIntegrationTests.swift
//  TreeTopTests
//
//  Created by Lesly Reinoso on 8/6/25.
//

import XCTest
import SwiftData
import UIKit
@testable import TreeTop

final class CameraSummaryIntegrationTests: XCTestCase {



    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([Project.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [cfg])
        return ModelContext(container)
    }


    private func makeTestImage(size: CGSize = .init(width: 256, height: 256)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor.black.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height/2))
        }
    }



    private func fileCount(in folderURL: URL) -> Int {
        (try? FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ))?.count ?? 0
    }



    func test_cameraCapture_thenSummaryGenerator_asyncFlow_works() throws {
        // Arrange: SwiftData + project
        let ctx = try makeInMemoryContext()
        let projectManager = ProjectManager(modelContext: ctx)
        let project = try XCTUnwrap(projectManager.createProject(name: "Cam+Summary", date: .now))

        // Dest folders
        let d1Photos = try XCTUnwrap(project.photoFolderURL(forDiagonal: "Diagonal 1"))
        let d2Photos = try XCTUnwrap(project.photoFolderURL(forDiagonal: "Diagonal 2"))

        // Simulated camera
        let camera = CameraManager()

        // “Capture” and save images (2 for D1, 1 for D2)
        let img1 = makeTestImage()
        let img2 = makeTestImage()
        let img3 = makeTestImage()

        camera.capturedImage.append(img1)
        XCTAssertTrue(projectManager.saveImage(img1, to: project, inSubFolder: "Diagonal 1", type: "Photos"))

        // 👇 Add a tiny delay so timestamp-based filenames don't collide
        RunLoop.current.run(until: Date().addingTimeInterval(1.1))

        camera.capturedImage.append(img2)
        XCTAssertTrue(projectManager.saveImage(img2, to: project, inSubFolder: "Diagonal 1", type: "Photos"))

        camera.capturedImage.append(img3)
        XCTAssertTrue(projectManager.saveImage(img3, to: project, inSubFolder: "Diagonal 2", type: "Photos"))

        // Sanity: files landed where expected
        XCTAssertEqual(fileCount(in: d1Photos), 2)
        XCTAssertEqual(fileCount(in: d2Photos), 1)
        XCTAssertEqual(camera.capturedImage.count, 3)

        // Act: run async summary
        let progressExp = expectation(description: "progress called at least once")
        let completionExp = expectation(description: "completion called")

        var firstProgress: (msg: String, processed: Int, total: Int)?
        var lastSummary: SummaryResult?

        SummaryGenerator.createSummaryAsync(
            forProjectAt: try XCTUnwrap(project.folderURL),
            progressCallback: { message, processed, total in
                // Fulfill only once to avoid over-fulfill crash
                if firstProgress == nil {
                    firstProgress = (message, processed, total)
                    progressExp.fulfill()
                }
            },
            completion: { result in
                switch result {
                case .success(let summary):
                    lastSummary = summary
                case .failure(let error):
                    XCTFail("Summary generation failed: \(error)")
                }
                completionExp.fulfill()
            }
        )

        wait(for: [progressExp, completionExp], timeout: 12.0)

        // Assert: progress saw the correct total (3 images)
        let progress = try XCTUnwrap(firstProgress)
        XCTAssertEqual(progress.total, 3, "Total images discovered should match number saved to Photos")

        // Assert: summary keys present
        let summary = try XCTUnwrap(lastSummary)
        XCTAssertEqual(summary.diagonalAverages.keys.sorted(), ["Diagonal 1", "Diagonal 2"])

        // Averages should be valid percentages (MaskGenerator may return 0 depending on implementation)
        if let d1Avg = summary.diagonalAverages["Diagonal 1"] {
            XCTAssertTrue((0.0...100.0).contains(d1Avg), "Diagonal 1 average should be a percentage")
        } else {
            XCTFail("Missing Diagonal 1 average")
        }
        if let d2Avg = summary.diagonalAverages["Diagonal 2"] {
            XCTAssertTrue((0.0...100.0).contains(d2Avg), "Diagonal 2 average should be a percentage")
        } else {
            XCTFail("Missing Diagonal 2 average")
        }
        XCTAssertTrue((0.0...100.0).contains(summary.overallAverage), "Overall average should be a percentage")
    }
}
