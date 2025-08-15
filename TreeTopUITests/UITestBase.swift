import XCTest

class UITestBase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchEnvironment["UITEST"] = "1"   // safe even if your app ignores it
        app.launch()

        // Auto‑dismiss any system alerts (location, camera, etc.)
        addUIInterruptionMonitor(withDescription: "System Alerts") { alert in
            if alert.buttons["Allow"].exists { alert.buttons["Allow"].tap(); return true }
            if alert.buttons["OK"].exists { alert.buttons["OK"].tap(); return true }
            if alert.buttons["Don’t Allow"].exists { alert.buttons["Don’t Allow"].tap(); return true }
            return false
        }
        app.tap() // trigger the interruption monitor

        waitForMainScreen()
    }

    /// Wait until either the main menu or the projects list is visible.
    func waitForMainScreen(timeout: TimeInterval = 30) {
        let home = HomePage(app: app)
        let listTable = app.tables.firstMatch
        let spinner = app.activityIndicators.firstMatch
        let titleTreeTop = app.staticTexts["TreeTop"]   // seen on your Loading/Home

        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if home.isMainMenuLikelyVisible || listTable.exists { return }

            // If a loading/splash indicator is present, keep polling
            if spinner.exists || titleTreeTop.exists {
                RunLoop.current.run(until: Date().addingTimeInterval(0.25))
                continue
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        dumpUI("after launch (main screen not found)")
        XCTFail("Main screen didn’t appear in \(timeout)s")
    }

    /// Attach the current accessibility tree to the test log (handy when a selector fails).
    func dumpUI(_ note: String = "") {
        let txt = app.debugDescription
        let att = XCTAttachment(string: txt)
        att.lifetime = .keepAlways
        XCTContext.runActivity(named: "UI Dump \(note)") { activity in
            activity.add(att)
        }
        print(txt)
    }
}
