//
//  ProjectManagerTests.swift
//  TreeTopTests
//
//  Created by Ashley Sanchez on 7/19/25.
//

import XCTest
import SwiftData
@testable import TreeTop //access to internal functions

final class ProjectManagerTests: XCTestCase {
    
    var projectManager: ProjectManager!
    var mockModelContext: ModelContext!

    func createInMemoryModelContext() throws -> ModelContext {
        let schema = Schema([Project.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }
    
    override func setUpWithError() throws {
        //reset the model and manager before each test
        mockModelContext = try createInMemoryModelContext()
        projectManager = ProjectManager(modelContext: mockModelContext)
        
    }

    override func tearDownWithError() throws {
        projectManager = nil
        mockModelContext = nil
        
    }

    func testCreateProject() throws {
        let name = "Tree Analysis"
        let date = Date()
        let project = projectManager.createProject(name: name, date: date)
        
        XCTAssertNotNil(project, "Project should be created for a unique name")
        XCTAssertEqual(project?.name, name, "Project name should match input")
    }
    
    func testSaveInMem() throws {
        let name = "Stored Project"
        let date = Date()
        
        _ = projectManager.createProject(name: name, date: date)
        
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate { $0.name == name }
        )
        
        let results = try mockModelContext.fetch(descriptor)
        
        XCTAssertEqual(results.count, 1, "Exactly one project should be stored")
        XCTAssertEqual(results.first?.name, name, "Stored project's name should match")
    }
    
    func testNoDup() {
        let name = "Test Dup Project"
        let date = Date()
        
        _ = projectManager.createProject(name: name, date: date)
        
        let second = projectManager.createProject(name: name, date: date)
        
        XCTAssertNil(second, "Duplicate project was created when it shouldn't")
    }
    
    func testFolderStructure() throws {
        let name = "Folder Test Structure"
        let date = Date()
        
        let project = projectManager.createProject(name: name, date: date)
        XCTAssertNotNil(project, "Project should be created")
        
        guard let folderURL = project?.folderURL else {
            XCTFail("folder URL should not be nil")
            return
        }
        
        let paths = [
            folderURL.appendingPathComponent("Diagonal 1"),
            folderURL.appendingPathComponent("Diagonal 2"),
            folderURL.appendingPathComponent("Diagonal 1/Photos"),
            folderURL.appendingPathComponent("Diagonal 1/Masks"),
            folderURL.appendingPathComponent("Diagonal 2/Photos"),
            folderURL.appendingPathComponent("Diagonal 2/Masks")
        ]
        
        for path in paths {
            XCTAssertTrue(FileManager.default.fileExists(atPath: path.path), "Missing folder: \(path.path)")
        }
    }
    
    func testDeleteProject() throws {
        let name = "Delete Test"
        let date = Date()
        
        let project = projectManager.createProject(name: name, date: date)
        XCTAssertNotNil(project, "Project should be created")
        
        let preDelete = try mockModelContext.fetch(FetchDescriptor<Project>())
        XCTAssertEqual(preDelete.count, 1, "One project should exist before deletion")
        
        if let project = project {
            projectManager.delete(project)
        }
        
        let postDelete = try mockModelContext.fetch(FetchDescriptor<Project>())
        XCTAssertEqual(postDelete.count, 0, "No projects should remain after deletion")
        
        if let folderURL = project?.folderURL {
            XCTAssertFalse(FileManager.default.fileExists(atPath: folderURL.path), "Project folder should be deleted from disk")
        }
    }
    
    func testSaveImage() throws {
        let project = try XCTUnwrap(projectManager.createProject(name: "Image Test", date: .now))
        
        let testImage = UIImage(systemName: "photo")!
        let result = projectManager.saveImage(testImage, to: project, inSubFolder: "Diagonal 1", type: "Photos")
        XCTAssertTrue(result, "Image should be saved successfully")
    }
    
    func testSaveImageFail() throws {
        let project = try XCTUnwrap(projectManager.createProject(name: "Bad Type Test", date: .now))
        let testImage = UIImage(systemName: "photo")!
        
        let result = projectManager.saveImage(testImage, to: project, inSubFolder: "Diagonal 1", type: "InvalidType")
        XCTAssertFalse(result, "Invalid image type should return false")
    }
    
    func testNameValidation() throws {
        let context = try createInMemoryModelContext()
        let manager = ProjectManager(modelContext: context)
        
        let project1 = manager.createProject(name: "   ", date: .now)
        XCTAssertNil(project1, "Project should not be created with only whitespace")
        
        let project2 = manager.createProject(name: "Valid Project", date: .now)
        XCTAssertNotNil(project2, "Project with valide name should be created")
        
        let project3 = manager.createProject(name: "   valid project  ", date: .now)
        XCTAssertNil(project3, "Project name should be considered duplicate even with different spacing/case")
    }
    
    func testProjectProperties() throws {
        let context = try createInMemoryModelContext()
        let manager = ProjectManager(modelContext: context)
        
        let date = Date()
        let name = "Project Test"
        guard let project = manager.createProject(name: name, date: date) else {
            XCTFail("Project was not created")
            return
        }
        
        XCTAssertEqual(project.name, name, "Project name does not match")
        XCTAssertEqual(project.date.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 1.0, "Project date does not match")
        XCTAssertTrue(project.folderName.contains(name), "Folder name should contain project name")
        XCTAssertNotNil(project.folderURL, "folderURL should not be nil")
    }
}
