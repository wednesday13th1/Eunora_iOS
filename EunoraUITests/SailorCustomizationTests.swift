import XCTest

final class SailorCustomizationTests: XCTestCase {
    @MainActor
    func testOutfitAndCabinPersistAcrossRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-hasCompletedOnboarding", "YES"]
        app.launch()
        openSailor(in: app)

        let hat = app.buttons["Cozy Beanie"]
        XCTAssertTrue(hat.waitForExistence(timeout: 8))
        let chosenHat = hat.value as? String == "Equipped" ? app.buttons["Sailor Cap"] : hat
        chosenHat.tap()
        XCTAssertEqual(chosenHat.value as? String, "Equipped")

        app.buttons["Jacket"].tap()
        let hoodie = app.buttons["Pink Hoodie"]
        let chosenJacket = hoodie.value as? String == "Equipped" ? app.buttons["Sailor Stripes"] : hoodie
        chosenJacket.tap()
        XCTAssertEqual(chosenJacket.value as? String, "Equipped")
        screenshot("Sailor Avatar", app)

        let couch = app.buttons["Comfy Couch"]
        let room = app.staticTexts["Boat Cabin Interior"]
        let scroll = app.scrollViews.firstMatch
        scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.76))
            .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.36)))
        reveal(couch, in: app)
        XCTAssertTrue(room.isHittable)
        let wasPlaced = couch.value as? String == "Placed ✓"
        couch.tap()
        let isPlaced = !wasPlaced
        XCTAssertEqual(couch.value as? String == "Placed ✓", isPlaced)
        screenshot("Boat Cabin Interior", app)

        app.terminate()
        app.launch()
        openSailor(in: app)
        XCTAssertTrue(chosenHat.waitForExistence(timeout: 8))
        XCTAssertEqual(chosenHat.value as? String, "Equipped")
        app.buttons["Jacket"].tap()
        XCTAssertEqual(chosenJacket.value as? String, "Equipped")
        reveal(couch, in: app)
        XCTAssertEqual(couch.value as? String == "Placed ✓", isPlaced)
    }

    @MainActor
    private func openSailor(in app: XCUIApplication) {
        let tab = app.buttons["Sailor"]
        let heading = app.staticTexts["Sailor Avatar"]
        XCTAssertTrue(tab.waitForExistence(timeout: 8))
        for _ in 0..<2 where !heading.exists {
            tab.tap()
            if heading.waitForExistence(timeout: 3) { return }
        }
        XCTAssertTrue(heading.exists)
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<5 where !element.isHittable {
            app.scrollViews.firstMatch.swipeUp(velocity: .slow)
        }
        XCTAssertTrue(element.isHittable)
    }

    @MainActor
    private func screenshot(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
