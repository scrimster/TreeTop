import XCTest

/// Page object for the TreeTop main menu.
struct HomePage {
    let app: XCUIApplication

    var newProject: XCUIElement {
        if app.buttons["New Project"].exists { return app.buttons["New Project"] }
        if app.staticTexts["New Project"].exists { return app.staticTexts["New Project"] }
        return app.descendants(matching: .any)
            .matching(NSPredicate(format:"label CONTAINS[c] %@", "New Project")).firstMatch
    }

    var existingProjects: XCUIElement {
        if app.buttons["Existing Projects"].exists { return app.buttons["Existing Projects"] }
        if app.staticTexts["Existing Projects"].exists { return app.staticTexts["Existing Projects"] }
        return app.descendants(matching: .any)
            .matching(NSPredicate(format:"label CONTAINS[c] %@", "Existing")).firstMatch
    }

    var about: XCUIElement {
        if app.buttons["About TreeTop"].exists { return app.buttons["About TreeTop"] }
        if app.staticTexts["About TreeTop"].exists { return app.staticTexts["About TreeTop"] }
        return app.descendants(matching: .any)
            .matching(NSPredicate(format:"label CONTAINS[c] %@", "About")).firstMatch
    }

    var howTo: XCUIElement {
        if app.buttons["How to Use"].exists { return app.buttons["How to Use"] }
        if app.staticTexts["How to Use"].exists { return app.staticTexts["How to Use"] }
        return app.descendants(matching: .any)
            .matching(NSPredicate(format:"label CONTAINS[c] %@", "How to")).firstMatch
    }

    var map: XCUIElement {
        if app.buttons["Map"].exists { return app.buttons["Map"] }
        if app.staticTexts["Map"].exists { return app.staticTexts["Map"] }
        return app.descendants(matching: .any)
            .matching(NSPredicate(format:"label CONTAINS[c] %@", "Map")).firstMatch
    }

    /// Use this to decide if the main menu is probably on screen.
    var isMainMenuLikelyVisible: Bool {
        newProject.exists || existingProjects.exists || about.exists || howTo.exists || map.exists
    }

    // Optional: keep this alias if any older tests referenced `anyPrimary`
    var anyPrimary: XCUIElement {
        if newProject.exists { return newProject }
        if existingProjects.exists { return existingProjects }
        if about.exists { return about }
        if howTo.exists { return howTo }
        if map.exists { return map }
        return app.descendants(matching: .any)
            .matching(NSPredicate(format:
                "label IN {'New Project','Existing Projects','About TreeTop','How to Use','Map'}"
            ))
            .firstMatch
    }
}

/// Minimal projects list page (lets the base wait detect a list landing screen)
struct ProjectListPage {
    let app: XCUIApplication
    var table: XCUIElement { app.tables.firstMatch }
}
