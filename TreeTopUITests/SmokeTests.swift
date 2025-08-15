import XCTest

final class SmokeTests: UITestBase {

    func test_home_has_primary_actions() {
        let home = HomePage(app: app)
        XCTAssertTrue(
            home.isMainMenuLikelyVisible,
            "Main menu should expose at least one primary action."
        )
    }

    func test_open_existing_projects_if_present() {
        let home = HomePage(app: app)
        if home.existingProjects.exists {
            home.existingProjects.tap()
            XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 5),
                          "Projects list should appear after tapping Existing Projects.")
        }
    }

    func test_navigate_about_if_present() {
        let home = HomePage(app: app)
        if home.about.exists {
            home.about.tap()
            XCTAssertTrue(
                app.staticTexts
                    .containing(NSPredicate(format:"label CONTAINS[c] %@", "About"))
                    .firstMatch
                    .waitForExistence(timeout: 5),
                "About screen text should appear"
            )
        }
    }
}
