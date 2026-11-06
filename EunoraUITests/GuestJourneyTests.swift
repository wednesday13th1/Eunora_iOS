import XCTest

final class GuestJourneyTests: XCTestCase {
    @MainActor
    func testGuestCanNavigateAndReturnWithoutAnAccount() {
        let app = XCUIApplication()
        app.launchArguments = ["--reset-welcome-for-ui-test"]
        app.launch()
        let welcome = app.buttons["Begin my voyage"]
        XCTAssertTrue(welcome.waitForExistence(timeout: 8))
        welcome.tap()
        XCTAssertTrue(app.buttons["Map"].waitForExistence(timeout: 8))

        app.buttons["Map"].tap()
        XCTAssertTrue(app.staticTexts["Chart your course"].exists)
        app.buttons["Quests"].tap()
        XCTAssertTrue(app.staticTexts["Daily Voyage Tasks"].exists)
        app.buttons["Sailor"].tap()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label ==[c] %@", "Data and privacy")).firstMatch.exists)
        app.terminate()

        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.buttons["Map"].waitForExistence(timeout: 8))
        XCTAssertFalse(welcome.exists)
    }

    @MainActor
    func testQuestProgressSurvivesRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-hasCompletedOnboarding", "YES"]
        app.launch()
        app.buttons["Quests"].tap()
        let progress = app.descendants(matching: .any)["quest-progress"].firstMatch
        XCTAssertTrue(progress.waitForExistence(timeout: 8))
        let startingProgress = progress.label
        let stamp = app.buttons["Stamp quest complete"].firstMatch
        XCTAssertTrue(stamp.waitForExistence(timeout: 8))
        if !stamp.isHittable { app.swipeUp() }
        stamp.tap()
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            progress.label != startingProgress
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 8), .completed)
        let earnedProgress = progress.label
        app.terminate()
        app.launch()
        app.buttons["Quests"].tap()
        XCTAssertTrue(progress.waitForExistence(timeout: 8))
        XCTAssertEqual(progress.label, earnedProgress)
    }

    @MainActor
    func testQuestHeadingScalesAndNavigationStaysReachable() {
        let app = XCUIApplication()
        app.launchArguments = ["-hasCompletedOnboarding", "YES", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"]
        app.launch()
        app.buttons["Quests"].tap()
        let heading = app.staticTexts["Daily Voyage Tasks"]
        XCTAssertTrue(heading.waitForExistence(timeout: 8))
        let defaultHeight = heading.frame.height
        app.terminate()

        app.launchArguments = ["-hasCompletedOnboarding", "YES", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        app.buttons["Quests"].tap()
        XCTAssertTrue(heading.waitForExistence(timeout: 8))
        XCTAssertGreaterThan(heading.frame.height, defaultHeight)
        for tab in ["Home", "Map", "Quests", "Letters", "Get Help", "Sailor"] {
            let button = app.buttons[tab]
            XCTAssertTrue(button.isHittable, tab)
            XCTAssertGreaterThanOrEqual(button.frame.width, 44, tab)
            XCTAssertGreaterThanOrEqual(button.frame.height, 44, tab)
        }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Quests at the largest accessibility text size"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testGuestCanOpenAndCloseBottle() {
        let app = XCUIApplication()
        app.launchArguments = ["-hasCompletedOnboarding", "YES"]
        app.launch()
        app.buttons["Letters"].tap()
        let cork = app.buttons["Bottle cork"]
        XCTAssertTrue(cork.waitForExistence(timeout: 8))
        if !cork.isHittable { app.swipeUp() }
        cork.tap()
        let close = app.buttons["Close letter"]
        XCTAssertTrue(close.waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Maya, 19"].exists)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Open letter"
        shot.lifetime = .keepAlways
        add(shot)
        close.tap()
        XCTAssertTrue(cork.waitForExistence(timeout: 8))
    }
}
