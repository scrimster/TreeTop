//
//  SummaryGeneratorTests.swift
//  TreeTopTests
//
//  Created by Lesly Reinoso on 8/3/25.
//

import XCTest
import UIKit
@testable import TreeTop

final class SummaryGeneratorTests: XCTestCase {

    // Create a fresh temp “project” with the expected diagonal structure.
    private func makeEmptyProjectFolder() throws -> URL {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("TreeTop_SummaryTests_\(UUID().uuidString)")

        let paths = [
            "Diagonal 1/Photos",
            "Diagonal 1/Masks",
            "Diagonal 2/Photos",
            "Diagonal 2/Masks",
        ]
        try paths.forEach { rel in
            try FileManager.default.createDirectory(
                at: base.appendingPathComponent(rel),
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        return base
    }

    private func removeFolderIfExists(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Synchronous summary

    func test_createSummary_emptyProject_returnsZeroAverages() throws {
        let projectURL = try makeEmptyProjectFolder()
        defer { removeFolderIfExists(projectURL) }

        let result = SummaryGenerator.createSummary(forProjectAt: projectURL)

        // Keys exist
        XCTAssertEqual(result.diagonalAverages.keys.sorted(), ["Diagonal 1", "Diagonal 2"])

        // Unwrap values before asserting
        let d1 = try XCTUnwrap(result.diagonalAverages["Diagonal 1"], "Missing Diagonal 1 average")
        let d2 = try XCTUnwrap(result.diagonalAverages["Diagonal 2"], "Missing Diagonal 2 average")

        XCTAssertEqual(d1, 0.0, accuracy: 1e-9)
        XCTAssertEqual(d2, 0.0, accuracy: 1e-9)

        // Overall average should also be 0.0
        XCTAssertEqual(result.overallAverage, 0.0, accuracy: 1e-9)
    }

    // MARK: - Async summary

    func test_createSummaryAsync_emptyProject_reportsProgress_andCompletes() throws {
        let projectURL = try makeEmptyProjectFolder()
        defer { removeFolderIfExists(projectURL) }

        let progressExp = expectation(description: "progress called at least once")
        let completionExp = expectation(description: "completion called")

        var progressCalls: [(String, Int, Int)] = []

        SummaryGenerator.createSummaryAsync(
            forProjectAt: projectURL,
            progressCallback: { (message, processed, total) in
                progressCalls.append((message, processed, total))
                progressExp.fulfill()
            },
            completion: { result in
                switch result {
                case .success(let summary):
                    XCTAssertEqual(summary.diagonalAverages.keys.sorted(), ["Diagonal 1", "Diagonal 2"])

                    let d1 = try? XCTUnwrap(summary.diagonalAverages["Diagonal 1"])
                    let d2 = try? XCTUnwrap(summary.diagonalAverages["Diagonal 2"])

                    XCTAssertEqual(d1 ?? -1, 0.0, accuracy: 1e-9)
                    XCTAssertEqual(d2 ?? -1, 0.0, accuracy: 1e-9)
                    XCTAssertEqual(summary.overallAverage, 0.0, accuracy: 1e-9)
                case .failure(let error):
                    XCTFail("Async summary should succeed for empty project, got error: \(error)")
                }
                completionExp.fulfill()
            }
        )

        wait(for: [progressExp, completionExp], timeout: 5.0)

        // Sanity on progress content
        XCTAssertFalse(progressCalls.isEmpty)
        if let first = progressCalls.first {
            XCTAssertTrue(first.0.contains("Initializing")) // message
            XCTAssertEqual(first.1, 0) // processed
            XCTAssertEqual(first.2, 0) // total
        }
    }
}
