//
//  ExpenseMyUITests.swift
//  ExpenseMyUITests
//
//  Created by Manan Gurung on 06/05/26.
//
// MARK: - Accessibility Identifiers Required
// The following identifiers must be added to SwiftUI views by Manan before these tests will pass.
// See docs/ui-test-accessibility-ids.md for the full table and instructions.
//
// HomeView (TabView container):      "homeView"
// Dashboard tab bar item:            "tab_dashboard"
// Transactions tab bar item:         "tab_transactions"
// Add SMS tab bar item:              "tab_addSMS"
// DashboardView root ScrollView:     "dashboardScrollView"
// Dashboard hero card:               "dashboardHeroCard"
// Dashboard donut chart (SpendRing): "dashboardDonutChart"
// Dashboard bar chart (MonthBar):    "dashboardBarChart"
// TransactionListView root VStack:   "transactionListView"
// Transaction List (List element):   "transactionList"
// Empty state in TransactionList:    "transactionEmptyState"
// Dashboard empty state view:        "dashboardEmptyState"
// AddTransactionView root:           "addTransactionView"
// Parse SMS Button:                  "parseSMSButton"
// SMS TextEditor:                    "smsTextEditor"

import XCTest

final class ExpenseMyUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Reset state on each test run so fresh-launch empty-state tests are reliable
        app.launchArguments = ["--uitesting", "--reset-data"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Launch

    @MainActor
    func testAppLaunchesSuccessfully() throws {
        XCTAssertEqual(
            app.state,
            .runningForeground,
            "App should be in the foreground immediately after launch"
        )
    }

    // MARK: - Home View

    @MainActor
    func testHomeViewIsDisplayedOnLaunch() throws {
        // The TabView should be visible — check for at least two tab bar buttons
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.waitForExistence(timeout: 5),
            "Tab bar should be visible on launch"
        )
        XCTAssertTrue(
            tabBar.buttons["Dashboard"].exists,
            "Dashboard tab should exist"
        )
        XCTAssertTrue(
            tabBar.buttons["Transactions"].exists,
            "Transactions tab should exist"
        )
        XCTAssertTrue(
            tabBar.buttons["Add SMS"].exists,
            "Add SMS tab should exist"
        )
    }

    // MARK: - Navigation

    @MainActor
    func testNavigationToDashboard() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        tabBar.buttons["Dashboard"].tap()

        // "SpendSense" headline is always rendered regardless of data state
        let headline = app.staticTexts["SpendSense"]
        XCTAssertTrue(
            headline.waitForExistence(timeout: 5),
            "Dashboard headline 'SpendSense' should be visible after tapping Dashboard tab"
        )
    }

    @MainActor
    func testNavigationToTransactionList() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        tabBar.buttons["Transactions"].tap()

        // Navigation title is always present
        let navTitle = app.navigationBars["Transactions"].firstMatch
        XCTAssertTrue(
            navTitle.waitForExistence(timeout: 5),
            "Transactions navigation bar title should appear after tapping Transactions tab"
        )
    }

    // MARK: - Add Transaction

    @MainActor
    func testAddTransactionButtonExists() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        tabBar.buttons["Add SMS"].tap()

        // "Parse SMS" button is always rendered in AddTransactionView
        let parseButton = app.buttons["parseSMSButton"]
        let parseButtonByLabel = app.buttons["Parse SMS"]

        let buttonExists = parseButton.waitForExistence(timeout: 5) ||
                           parseButtonByLabel.waitForExistence(timeout: 5)
        XCTAssertTrue(
            buttonExists,
            "Parse SMS button should be accessible in AddTransactionView"
        )
    }

    // MARK: - Empty State

    @MainActor
    func testEmptyStateVisibleOnFreshLaunch() throws {
        // With --reset-data launch argument the store is empty.
        // Dashboard shows its inline empty state; Transactions shows its own.
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        // Check dashboard empty state first
        tabBar.buttons["Dashboard"].tap()
        let dashboardEmptyState = app.otherElements["dashboardEmptyState"]
        let dashboardEmptyText = app.staticTexts["Nothing here yet!"]

        let dashboardEmpty = dashboardEmptyState.waitForExistence(timeout: 5) ||
                             dashboardEmptyText.waitForExistence(timeout: 5)
        XCTAssertTrue(
            dashboardEmpty,
            "Dashboard should show empty state when there are no transactions"
        )

        // Check transaction list empty state
        tabBar.buttons["Transactions"].tap()
        let listEmptyState = app.otherElements["transactionEmptyState"]
        let listEmptyText = app.staticTexts["No transactions found"]

        let listEmpty = listEmptyState.waitForExistence(timeout: 5) ||
                        listEmptyText.waitForExistence(timeout: 5)
        XCTAssertTrue(
            listEmpty,
            "Transaction list should show empty state when there are no transactions"
        )
    }

    // MARK: - Dashboard Charts

    @MainActor
    func testDashboardShowsChartElements() throws {
        // Charts only render when there is data; seed via accessibility identifier fallback.
        // This test verifies the chart container identifiers are present in the hierarchy
        // when data exists. On a fresh install the donut/bar containers are in the layout
        // even with empty data arrays (they render with zero-value segments).
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        tabBar.buttons["Dashboard"].tap()

        let scrollView = app.scrollViews["dashboardScrollView"].firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
        } else {
            app.swipeUp()
        }

        let donutChart = app.otherElements["dashboardDonutChart"]
        let barChart   = app.otherElements["dashboardBarChart"]

        // At minimum the containers must be reachable in the hierarchy
        let chartsReachable = donutChart.waitForExistence(timeout: 5) ||
                              barChart.waitForExistence(timeout: 5)
        XCTAssertTrue(
            chartsReachable,
            "Dashboard chart containers (donut or bar) should exist in the view hierarchy"
        )
    }

    // MARK: - Background / Foreground

    @MainActor
    func testAppHandlesBackgroundAndForeground() throws {
        XCTAssertEqual(app.state, .runningForeground)

        XCUIDevice.shared.press(.home)

        // Wait until the app moves to background
        let backgrounded = XCTWaiter.wait(
            for: [XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "state == %d", XCUIApplication.State.runningBackground.rawValue),
                object: app
            )],
            timeout: 5
        )
        XCTAssertEqual(backgrounded, .completed, "App should enter background after Home button press")

        // Re-activate
        app.activate()

        XCTAssertEqual(
            app.state,
            .runningForeground,
            "App should return to foreground after re-activation without crashing"
        )

        // Verify core UI is still intact
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.exists,
            "Tab bar should still be visible after backgrounding and foregrounding"
        )
    }
}
