//
//  ProjectCameraIntergrationTests.swift
//  TreeTopTests
//
//  Created by Lesly Reinoso on 8/6/25.
//

import XCTest
import SwiftData
import UIKit
@testable import TreeTop

final class ProjectCameraIntegrationTests: XCTestCase {



    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([Project.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
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
        (try? FileManager.default.contentsOfDirectory(at: folderURL,
                                                      includingPropertiesForKeys: nil,
                                                      options: [.skipsHiddenFiles]))?.count ?? 0
    }



    func test_captureImage_thenSaveWithProjectManager_succeeds_andFileAppears() throws {
        // Arrange: in-memory model, project, managers
        let ctx = try makeInMemoryContext()
        let projectManager = ProjectManager(modelContext: ctx)
        guard let project = projectManager.createProject(name: "Cam-Project", date: .now) else {
            return XCTFail("Failed to create project")
        }

        let camera = CameraManager()
        let testImage = makeTestImage()

        // Destination folder (Diagonal 1 / Photos)
        guard let photosFolder = project.photoFolderURL(forDiagonal: "Diagonal 1") else {
            return XCTFail("Missing Diagonal 1 Photos folder URL")
        }
        let beforeCount = fileCount(in: photosFolder)

        // Act: simulate a capture (no real camera) and then save via ProjectManager
        camera.capturedImage.append(testImage)

        let saved = projectManager.saveImage(testImage,
                                             to: project,
                                             inSubFolder: "Diagonal 1",
                                             type: "Photos")

        // Assert: save returned true and file appeared on disk
        XCTAssertTrue(saved, "Expected ProjectManager.saveImage to succeed")

        let afterCount = fileCount(in: photosFolder)
        XCTAssertEqual(afterCount, beforeCount + 1, "Photos folder should have one more image")

        // CameraManager should still reflect the captured moment
        XCTAssertEqual(camera.capturedImage.count, 1)
    }

    func test_multipleCaptures_savedToCorrectDiagonalFolders() throws {
        // Arrange
        let ctx = try makeInMemoryContext()
        let projectManager = ProjectManager(modelContext: ctx)
        let project = try XCTUnwrap(projectManager.createProject(name: "MultiDiag", date: .now))

        guard
            let d1Photos = project.photoFolderURL(forDiagonal: "Diagonal 1"),
            let d2Photos = project.photoFolderURL(forDiagonal: "Diagonal 2")
        else { return XCTFail("Missing diagonal photo folders") }

        let d1Before = fileCount(in: d1Photos)
        let d2Before = fileCount(in: d2Photos)

        let camera = CameraManager()
        let img1 = makeTestImage()
        let img2 = makeTestImage()

        // Act: pretend camera captured two images, save to different diagonals
        camera.capturedImage.append(img1)
        XCTAssertTrue(projectManager.saveImage(img1, to: project, inSubFolder: "Diagonal 1", type: "Photos"))

        camera.capturedImage.append(img2)
        XCTAssertTrue(projectManager.saveImage(img2, to: project, inSubFolder: "Diagonal 2", type: "Photos"))

        // Assert: counts increased in the right places
        XCTAssertEqual(fileCount(in: d1Photos), d1Before + 1)
        XCTAssertEqual(fileCount(in: d2Photos), d2Before + 1)

        // Sanity: camera has both images in its buffer
        XCTAssertEqual(camera.capturedImage.count, 2)
    }
}
