# UI Test Accessibility Identifiers

This document lists the `.accessibilityIdentifier` values that must be added to SwiftUI views before the UI tests in `ExpenseMyUITests/ExpenseMyUITests.swift` will pass.

---

## For Manan: How to add an accessibility identifier

In SwiftUI, attach `.accessibilityIdentifier("id")` as a modifier to any view:

```swift
// Example — attach to the outermost container of a screen
VStack { ... }
    .accessibilityIdentifier("dashboardScrollView")

// Example — attach to a specific element
Button("Parse SMS") { ... }
    .accessibilityIdentifier("parseSMSButton")
```

Prefer attaching the identifier to the **outermost** container of a screen or to the specific interactive element that the test needs to find. Identifiers do **not** appear in production builds in a user-visible way, but they are picked up by XCUI at test time.

---

## Required Identifiers

| View | Element | Suggested `accessibilityIdentifier` | Used In Test |
|---|---|---|---|
| `HomeView` | Root `TabView` | `homeView` | `testHomeViewIsDisplayedOnLaunch` |
| `HomeView` | Dashboard tab bar button | `tab_dashboard` | `testNavigationToDashboard` |
| `HomeView` | Transactions tab bar button | `tab_transactions` | `testNavigationToTransactionList` |
| `HomeView` | Add SMS tab bar button | `tab_addSMS` | `testAddTransactionButtonExists` |
| `DashboardView` | Root `ScrollView` | `dashboardScrollView` | `testDashboardShowsChartElements` |
| `DashboardView` | Hero total card (`ZStack`) | `dashboardHeroCard` | `testNavigationToDashboard` |
| `DashboardView` | `SpendRingView` container | `dashboardDonutChart` | `testDashboardShowsChartElements` |
| `DashboardView` | `MonthBarChart` container | `dashboardBarChart` | `testDashboardShowsChartElements` |
| `DashboardView` | Inline empty-state `VStack` | `dashboardEmptyState` | `testEmptyStateVisibleOnFreshLaunch` |
| `TransactionListView` | Root `VStack` | `transactionListView` | `testNavigationToTransactionList` |
| `TransactionListView` | `List` element | `transactionList` | `testNavigationToTransactionList` |
| `TransactionListView` | Empty state `VStack` | `transactionEmptyState` | `testEmptyStateVisibleOnFreshLaunch` |
| `AddTransactionView` | Root `NavigationStack` / `ScrollView` | `addTransactionView` | `testAddTransactionButtonExists` |
| `AddTransactionView` | Parse SMS `Button` | `parseSMSButton` | `testAddTransactionButtonExists` |
| `AddTransactionView` | SMS `TextEditor` | `smsTextEditor` | Future paste-and-parse tests |
| `TransactionRow` | Each row `HStack` | `transactionRow_<id>` | Future row-tap tests |

---

## Notes

- **Tab bar buttons**: iOS automatically exposes tab bar items with their label text (e.g. `"Dashboard"`, `"Transactions"`, `"Add SMS"`). The tests currently rely on these text labels, so the tab identifiers above are optional but recommended for robustness.
- **`--reset-data` launch argument**: The test suite passes `--reset-data` in `launchArguments`. The app should detect this in `ExpenseMyApp.swift` and use an in-memory `ModelContainer` so tests start from a clean state every run. Example:

```swift
// In ExpenseMyApp.swift
let isUITesting = CommandLine.arguments.contains("--uitesting")
let resetData   = CommandLine.arguments.contains("--reset-data")

let container = try! ModelContainer(
    for: Transaction.self,
    configurations: ModelConfiguration(isStoredInMemoryOnly: isUITesting && resetData)
)
```

- **`SpendRingView` and `MonthBarChart`**: These use Swift Charts. Add `.accessibilityIdentifier` to the outermost `VStack` or `ZStack` that wraps the `Chart` view, not to the `Chart` itself.
