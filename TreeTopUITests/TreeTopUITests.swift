import XCTest

final class TreeTopUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func test_mainMenuButtonsExist() {
        let home = HomePage(app: app)

        XCTAssertTrue(home.newProject.exists, "New Project button should exist")
        XCTAssertTrue(home.existingProjects.exists, "Existing Projects button should exist")
        XCTAssertTrue(home.about.exists, "About TreeTop button should exist")
        XCTAssertTrue(home.howTo.exists, "How to Use button should exist")
        XCTAssertTrue(home.map.exists, "Map button should exist")
    }

    func test_isMainMenuLikelyVisible_returnsTrue() {
        let home = HomePage(app: app)
        XCTAssertTrue(home.isMainMenuLikelyVisible, "Main menu should be visible")
    }

    func test_tap_about_shows_about_screen() {
        let home = HomePage(app: app)
        if home.about.exists {
            home.about.tap()

            let aboutText = app.staticTexts
                .containing(NSPredicate(format: "label CONTAINS[c] %@", "About"))
                .firstMatch

            XCTAssertTrue(aboutText.waitForExistence(timeout: 5),
                          "About screen content should appear")
        }
    }
}
