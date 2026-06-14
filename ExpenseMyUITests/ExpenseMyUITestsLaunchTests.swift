//
//  ExpenseMyUITestsLaunchTests.swift
//  ExpenseMyUITests
//
//  Created by Manan Gurung on 06/05/26.
//

import XCTest

final class ExpenseMyUITestsLaunchTests: XCTestCase {

    // Run once per UI configuration (light + dark) for the screenshot tests
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Performance

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    // MARK: - Visual Regression Reference Screenshots

    @MainActor
    func testLaunchAndTakeScreenshot() throws {
        let app = XCUIApplication()
        app.launch()

        // Allow the first frame to fully settle
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 5)

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Launch – Default"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testDarkModeLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UIUserInterfaceStyle", "2"] // 2 = Dark
        app.launch()

        _ = app.tabBars.firstMatch.waitForExistence(timeout: 5)

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Launch – Dark Mode"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLightModeLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UIUserInterfaceStyle", "1"] // 1 = Light
        app.launch()

        _ = app.tabBars.firstMatch.waitForExistence(timeout: 5)

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Launch – Light Mode"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
