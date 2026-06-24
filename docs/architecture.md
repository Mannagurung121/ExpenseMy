# ExpenseMy — Architecture

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          SwiftUI Views                          │
│   HomeView  DashBoardView  TransactionList  TransactionDetail   │
│   AddTransactionView  ParsedPreview  ShareResultView  Widget    │
└──────────────────────────┬──────────────────────────────────────┘
                           │ @Observable / @State / .environment
┌──────────────────────────▼──────────────────────────────────────┐
│                         ViewModels                              │
│           TransactionViewModel    DashboardViewModel            │
└──────────────────────────┬──────────────────────────────────────┘
                           │ ModelContext queries / computed props
       ┌───────────────────┼───────────────────────┐
       │                   │                       │
┌──────▼──────┐   ┌────────▼────────┐   ┌──────────▼──────────┐
│   Models    │   │    Services     │   │      Parsers        │
│ (SwiftData) │   │ Firebase wrappers│  │  SMSParser          │
│ Transaction │   │ KeychainService │   │  CategoryClassifier │
│ Category    │   │ SecureStorage   │   └─────────────────────┘
│ DateFilters │   └─────────────────┘
└──────┬──────┘
       │ SwiftData persistence
┌──────▼──────────────────────────────────────────────────────────┐
│                       Data Layer                                │
│   SwiftData ModelContainer (on-device SQLite)                   │
│   App Group shared container (main app ↔ Share Extension)       │
│   Apple Keychain (sensitive values)                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Layer Descriptions

### Views (SwiftUI)
Pure presentation layer. Views observe ViewModels via `@Observable` and render state. No business logic, no direct data access. All navigation is handled via SwiftUI's native stack and tab navigation.

### ViewModels (`@Observable`)
Hold filter state, sort order, and aggregation logic. Receive a `ModelContext` from the SwiftUI environment and execute SwiftData `FetchDescriptor` queries. Return derived data (grouped transactions, chart data points) to views as computed properties.

### Models (SwiftData `@Model`)
Persistent entities stored in the SwiftData `ModelContainer`. The primary model is `Transaction`. `Category` and `DateFilter` are value-type enums that support the model but are not themselves persisted as separate entities.

### Services
Typed Swift wrappers around external dependencies. No view or ViewModel imports an SDK directly.

- `AnalyticsService` — wraps `Firebase Analytics`; conditionally compiled with `#if canImport(FirebaseAnalytics)`
- `CrashlyticsService` — wraps `Firebase Crashlytics`; non-fatal error logging
- `RemoteConfigService` — wraps `Firebase Remote Config`; provides feature flags
- `KeychainService` — direct `Security` framework calls; save/load/delete raw `Data` and `String` values
- `SecureStorageService` — higher-level wrapper over `KeychainService`; typed accessors for named app values

### Parsers
Stateless structs with static methods. Zero dependencies on SwiftUI, SwiftData, or any service.

- `SMSParser` — entry point; validates the SMS is a transaction (not OTP/junk), then extracts amount, type, merchant, bank, and date via regex
- `CategoryClassifier` — maps extracted merchant names and raw SMS text to a `Category` enum value using keyword matching

### Extensions
`Color+Extensions.swift` — custom named colors for the app's design system, defined as `Color` static properties.

### Widgets
`SpendWidget` + `SpendWidgetBundle` — WidgetKit timeline provider that reads total spend for the current month from the App Group shared container and renders a home-screen widget.

### Share Extension
`ExpenseMyShare/ShareViewController` — receives shared text (SMS) from the iOS share sheet, runs it through `SMSParser`, and writes the result into the App Group shared container. The main app reads this on next launch.

---

## Data Flow

```
SMS Text (user shares via Share Extension or pastes in app)
    │
    ▼
SMSParser.parse(_:)
    ├── isTransactionSMS()    — filter out OTPs and non-transaction messages
    ├── extractAmount()       — regex: "Rs. 1,234.56" or "1234 INR"
    ├── extractType()         — keyword scan: credited/debited/refund/received
    ├── extractMerchant()     — UPI VPA patterns, "at MERCHANT on", "Info: UPI-X"
    ├── extractBank()         — keyword map: sbi/hdfc/icici/axis/kotak/...
    └── extractDate()         — multi-format DateFormatter: dd-MM-yy, dd/MM/yyyy, ...
    │
    ▼
CategoryClassifier.classify(merchant:rawText:)
    — keyword rules map merchant name → Category enum
    │
    ▼
Transaction (SwiftData @Model)
    — persisted into ModelContainer via ModelContext.insert() + save()
    │
    ▼
TransactionViewModel / DashboardViewModel
    — FetchDescriptor queries, filter/sort/group computed properties
    │
    ▼
SwiftUI Views
    — render list, charts, widgets
```

---

## Dependency Graph

```
Views ──────────────────────► ViewModels
  │                               │
  │                               ├──► Transaction (SwiftData)
  │                               └──► DateFilter (enum)
  │
  ├──► SMSParser ──────────────► CategoryClassifier
  │
  └──► Services
         ├── AnalyticsService   → FirebaseAnalytics (conditional)
         ├── CrashlyticsService → FirebaseCrashlytics (conditional)
         ├── RemoteConfigService→ FirebaseRemoteConfig (conditional)
         ├── KeychainService    → Security.framework
         └── SecureStorageService → KeychainService

Widgets ─────────────────────► App Group shared container
ShareExtension ──────────────► App Group shared container
                                    └──► SMSParser
```

---

## File-by-File Map

| File | Description |
|---|---|
| `ExpenseMyApp.swift` | App entry point; sets up `ModelContainer` and injects it into the environment |
| `Components/EmptyStateView.swift` | Reusable empty-state placeholder shown when the transaction list is empty |
| `Components/FilterPillView.swift` | Horizontal scrolling row of category filter chips |
| `Components/StatCard.swift` | Card component for summary statistics (total spend, income, net) |
| `Extensions/Color+Extensions.swift` | Named `Color` constants for the app's design palette |
| `Home/HomeView.swift` | Root tab bar view; hosts dashboard and transaction list tabs |
| `ModelViewUi/DashBoards/DashBoardView.swift` | Analytics screen; composes MonthBarChart and SpendRingView |
| `ModelViewUi/DashBoards/MonthBarChart.swift` | Monthly spend bar chart using the Charts framework |
| `ModelViewUi/DashBoards/SpendRingView.swift` | Donut chart showing spend breakdown by category |
| `Models/DateFilters.swift` | `DateFilter` enum (today/week/month/year/all) with computed `DateInterval` |
| `Models/SampleSmS.swift` | Hardcoded sample SMS strings for use in Xcode previews |
| `Models/Transactions.swift` | `Transaction` SwiftData `@Model`; `TransactionType` and `Category` enums |
| `Parsers/Category.swift` | `Category` enum cases with display names and SF Symbol icons |
| `Parsers/SmsParser.swift` | `SMSParser` static struct; all regex extraction logic lives here |
| `Services/AnalyticsService.swift` | Firebase Analytics wrapper; logs named events with typed parameters |
| `Services/CrashlyticsService.swift` | Firebase Crashlytics wrapper; records non-fatal errors with context |
| `Services/KeychainService.swift` | Low-level Keychain CRUD using the Security framework |
| `Services/RemoteConfigService.swift` | Firebase Remote Config wrapper; typed feature-flag accessors |
| `Services/SecureStorageService.swift` | High-level typed API over `KeychainService` |
| `SMS/AddTransactionView.swift` | Manual SMS input screen; calls `SMSParser` and shows parsed preview |
| `SMS/ParesdPreview.swift` | Read-only preview of a parsed transaction before the user confirms saving |
| `ShareExtensions/ShareResultView.swift` | SwiftUI result view shown inside the Share Extension context |
| `ShareExtensions/ShareViewController.swift` | `UIViewController` subclass that is the Share Extension entry point |
| `ShareExtensions/SharedDataManager.swift` | Reads/writes parsed transaction data to the App Group container |
| `Transactions/TransactionDTO.swift` | Codable data-transfer object for passing transaction data across extension boundaries |
| `Transactions/TransactionDetailView.swift` | Detail screen for a single transaction with edit-category action |
| `Transactions/TransactionList.swift` | Filtered, sorted, grouped list of transactions with search bar |
| `Transactions/TransactionRow.swift` | Single row cell in the transaction list |
| `ViewModels/DashboardViewModel.swift` | Aggregates transaction data into chart-ready data points |
| `ViewModels/TransactionViewModel.swift` | Holds filter, sort, search state; `filtered()` and `groupedByDate()` helpers |
| `Widgets/SpendWidget.swift` | WidgetKit `TimelineProvider` and widget view for home-screen spend display |
| `Widgets/SpendWidgetBundle.swift` | WidgetKit bundle entry point |
| `ExpenseMyShare/ShareViewController.swift` | Share Extension entry point for the separate `ExpenseMyShare` target |

---

## Design Decisions

### SwiftData over Core Data
SwiftData is the modern Apple persistence layer introduced in iOS 17. It integrates directly with the Swift type system via macros, requires zero boilerplate compared to `NSManagedObject` subclasses, and pairs naturally with `@Observable`. Since the app targets iOS 17+, there is no reason to use Core Data.

### Regex over ML for v1
The initial SMS parser uses hand-written regular expressions and keyword tables rather than a Core ML model. This choice was deliberate: regex patterns are deterministic, easy to test, zero-latency, and require no model binary in the app bundle. Indian bank SMS formats are structured enough that a rule-based approach achieves high accuracy. A Core ML upgrade is tracked in the roadmap for v2.

### Keychain over UserDefaults for sensitive data
`UserDefaults` stores values as a plaintext plist on disk. The iOS Keychain encrypts values with AES-256, protects them with the device passcode via the Secure Enclave, and excludes `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` items from backups. This directly addresses OWASP Mobile Top 10 M9 (Insecure Data Storage). See `Services/KeychainService.swift` for the full rationale comment.

### Conditional compilation for Firebase
`GoogleService-Info.plist` is gitignored; the repo cannot assume Firebase is always present. All Firebase service calls are wrapped in `#if canImport(Firebase...)` guards so the app compiles and runs without Firebase credentials. This keeps local development frictionless and prevents CI build failures on forks without secrets configured.
