//
//  ProjectUITests.swift
//  TreeTopUITests
//
//  Created by Ashley Sanchez on 7/19/25.
//

import XCTest

final class ProjectUITests: XCTestCase {
    var app: XCUIApplication!
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testCreateNewProject() throws {
        let createButton = app.buttons["createProjectButton"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5), "Create Project button should exist")
        createButton.tap()
        
        let nameField = app.textFields["projectNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Project name text field")
        nameField.tap()
        nameField.typeText("Test Project")
        
        let saveButton = app.buttons["saveProjectButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "Save Project button should exist")
        saveButton.tap()
        
        let newProjectCell = app.staticTexts["Test Project"]
        XCTAssertTrue(newProjectCell.waitForExistence(timeout: 5), "Newly created project should appear in the list")
    }
    
    @MainActor
    func testExistingProjectView() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

    }
    
    @MainActor
    func testDeleteProject() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

    }
}
