import XCTest

final class AltitudeNowUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testScreenshots() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        // Snapshot mode injects mock sensor data + fakes isSensorAvailable=true.
        XCTAssertTrue(app.staticTexts["Altitude"].waitForExistence(timeout: 10))

        // 1) Live readouts + chart.
        snapshot("01-Live")

        // 2) Sessions sheet.
        let sessionsButton = app.navigationBars.buttons.element(boundBy: 0)
        if sessionsButton.exists {
            sessionsButton.tap()
            sleep(1)
            snapshot("02-Sessions")
            let done = app.buttons["Done"]
            if done.exists { done.tap() }
        }

        // 3) Settings sheet.
        let settingsButton = app.navigationBars.buttons.element(boundBy: app.navigationBars.buttons.count - 1)
        if settingsButton.exists {
            settingsButton.tap()
            sleep(1)
            snapshot("03-Settings")
            let done = app.buttons["Done"]
            if done.exists { done.tap() }
        }

        // 4) Paywall via Unlock button in Settings.
        if settingsButton.exists {
            settingsButton.tap()
            sleep(1)
            let unlock = app.buttons["Unlock Premium"]
            if unlock.exists {
                unlock.tap()
                sleep(1)
                snapshot("04-Paywall")
            }
        }
    }
}
