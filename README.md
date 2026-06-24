<div align="center">

# ExpenseMy

**AI-powered iOS expense tracker that parses bank SMS messages into categorized transactions with analytics**

[![Build](https://github.com/Mannagurung121/ExpenseMy/actions/workflows/build.yml/badge.svg)](https://github.com/Mannagurung121/ExpenseMy/actions/workflows/build.yml)
[![Tests](https://github.com/Mannagurung121/ExpenseMy/actions/workflows/test.yml/badge.svg)](https://github.com/Mannagurung121/ExpenseMy/actions/workflows/test.yml)
[![SwiftLint](https://github.com/Mannagurung121/ExpenseMy/actions/workflows/swiftlint.yml/badge.svg)](https://github.com/Mannagurung121/ExpenseMy/actions/workflows/swiftlint.yml)
[![Security Scan](https://github.com/Mannagurung121/ExpenseMy/actions/workflows/security-scan.yml/badge.svg)](https://github.com/Mannagurung121/ExpenseMy/actions/workflows/security-scan.yml)

</div>

---

## Screenshots

<p align="center">
  <img width="220" alt="IMG_7013" src="https://github.com/user-attachments/assets/e16b3fbc-33ce-4d6e-a5cb-722ff11f89c8" />
  <img width="220" alt="IMG_7009" src="https://github.com/user-attachments/assets/94700bcc-5f41-4a76-8018-064135d5bee9" />
  <img width="220" alt="IMG_7012" src="https://github.com/user-attachments/assets/79571bbc-e6c3-454a-88c4-7613c28cd238" />
</p>

<p align="center">
  <img width="220" alt="IMG_7010" src="https://github.com/user-attachments/assets/0e595e1f-cdfa-4c36-bf2a-c3538668c1ac" />
  <img width="220" alt="IMG_7017" src="https://github.com/user-attachments/assets/df362fd0-0c28-488f-8ac2-b4df6eadc990" />
  <img width="220" alt="IMG_7011" src="https://github.com/user-attachments/assets/171350dc-5dbe-4dfc-a3f6-7e0f7c6605ab" />
</p>

<p align="center">
  <img width="220" alt="IMG_7018" src="https://github.com/user-attachments/assets/48eb4fae-e4e6-4d09-8e40-0f930d9910a3" />
  <img width="220" alt="IMG_7014" src="https://github.com/user-attachments/assets/49139e06-5753-42b5-9d8e-b61ce51c4a69" />
  <img width="220" alt="IMG_7015" src="https://github.com/user-attachments/assets/b6428c09-1e77-49be-9f6c-6e5488a53005" />
</p>

---

## Features

- **NLP-based SMS parsing** — regex engine extracts amount, merchant, bank, and transaction type from raw Indian bank SMS messages
- **Automatic expense tracking** — transactions are created and stored without manual entry
- **Smart categorization** — rule-based classifier maps merchants to categories (Food, Shopping, Travel, etc.)
- **Analytics dashboard** — monthly bar chart and category spend ring chart
- **iOS Widgets** — home screen widget showing current month spend via WidgetKit
- **Share Extension** — share any SMS directly from the Messages app to ExpenseMy
- **App Groups** — secure shared container between the main app and Share Extension
- **Local-only, privacy-first** — all data stays on device; no cloud sync, no accounts

---

## Tech Stack

| Category | Technology |
|---|---|
| UI | SwiftUI, Charts framework, WidgetKit |
| Data | SwiftData (on-device persistence) |
| Architecture | MVVM with `@Observable` ViewModels |
| CI/CD | GitHub Actions, Fastlane, Bundler |
| Security | Apple Keychain, TruffleHog, Danger |
| Analytics | Firebase Crashlytics, Firebase Analytics |
| Distribution | TestFlight (beta), App Store (release) |

---

## Architecture

ExpenseMy follows MVVM (Model-View-ViewModel) with a dedicated services layer beneath it.

- **Views** (SwiftUI) observe ViewModels and render state; no business logic lives in views.
- **ViewModels** (`@Observable`) hold filter, sort, and aggregation logic; they read from SwiftData via `ModelContext` passed from the environment.
- **Models** (`@Model`) are SwiftData entities — `Transaction` is the primary model.
- **Services** wrap Firebase (Crashlytics, Analytics, Remote Config) and Apple Keychain behind typed Swift interfaces so the rest of the app never touches SDKs directly.
- **Parsers** (`SMSParser`, `CategoryClassifier`) are stateless structs that convert raw SMS strings into `Transaction` values.

See [`docs/architecture.md`](docs/architecture.md) for a full layer diagram, data-flow diagram, and file-by-file map.

---

## Project Structure

```
ExpenseMy/
├── ExpenseMy/                  # Main app target
│   ├── ExpenseMyApp.swift      # App entry point, SwiftData container setup
│   ├── Components/             # Reusable UI components (StatCard, FilterPill, EmptyState)
│   ├── Extensions/             # Swift extensions (Color+Extensions)
│   ├── Home/                   # HomeView — tab bar root
│   ├── ModelViewUi/
│   │   └── DashBoards/         # DashBoardView, MonthBarChart, SpendRingView
│   ├── Models/                 # DateFilters, SampleSMS, Transactions (SwiftData @Model)
│   ├── Parsers/                # SMSParser, CategoryClassifier
│   ├── Services/               # Firebase wrappers, KeychainService, SecureStorageService
│   ├── SMS/                    # AddTransactionView, ParsedPreview
│   ├── ShareExtensions/        # ShareResultView, ShareViewController, SharedDataManager
│   ├── Transactions/           # TransactionDTO, Detail, List, Row views
│   ├── ViewModels/             # TransactionViewModel, DashboardViewModel
│   └── Widgets/                # SpendWidget, SpendWidgetBundle
├── ExpenseMyShare/             # Share Extension target
├── ExpenseMyTests/             # Unit tests (CategoryClassifier, Transaction model, SMS parsing)
├── ExpenseMyUITests/           # UI automation tests
├── fastlane/                   # Fastfile with test/build/beta/release lanes
├── docs/                       # Architecture, DevOps, security, and process documentation
├── .github/workflows/          # GitHub Actions CI/CD workflows
├── CHANGELOG.md                # Keep-a-Changelog format version history
├── CONTRIBUTING.md             # Contribution guidelines
├── SECURITY.md                 # Security policy and vulnerability reporting
└── LICENSE                     # MIT License
```

---

## Getting Started

### Prerequisites

- macOS 14+ (Sonoma or later)
- Xcode 16.2
- iOS 17+ simulator or device
- Ruby 3.2+ and Bundler (for Fastlane, optional for local development)

### Clone and Run

```bash
git clone https://github.com/Mannagurung121/ExpenseMy.git
cd ExpenseMy
open ExpenseMy.xcodeproj
```

Select the **ExpenseMy** scheme, choose an iPhone 16 simulator, and press **Run** (Cmd+R).

> **Note:** `GoogleService-Info.plist` is not committed to the repo (it is gitignored). Firebase features (Crashlytics, Analytics, Remote Config) are conditionally compiled — the app builds and runs fully without this file.

### Run Tests Locally

```bash
bundle install
bundle exec fastlane test
```

Or directly via Xcode: **Product → Test** (Cmd+U).

---

## CI/CD Pipeline

Every push and pull request to `main` runs through a multi-stage pipeline. See [`docs/ci-cd-overview.md`](docs/ci-cd-overview.md) for the full runbook.

| Stage | Workflow | Trigger |
|---|---|---|
| Lint | `swiftlint.yml` | Push + PR to `main` |
| Build | `build.yml` | Push + PR to `main` |
| Test | `test.yml` | Push + PR to `main` |
| Security Scan | `security-scan.yml` | PR to `main` |
| PR Review | `danger.yml` | PR to `main` |
| Version Check | `version-check.yml` | PR to `main` |
| Beta Deploy | `beta.yml` | Merge to `main` |
| Release | `release.yml` | Push of `v*.*.*` tag |

Full documentation: [`docs/devops-overview.md`](docs/devops-overview.md)

---

## Security

ExpenseMy handles financial data and is built with security as a first-class concern.

- All sensitive values (API keys, tokens) are stored in Apple Keychain, never in UserDefaults or plist files
- `GoogleService-Info.plist` and credentials are gitignored and injected at CI time via secrets
- Every PR is scanned for secrets with TruffleHog and for sensitive file leakage
- SPM dependencies are audited on every PR

Relevant documents:
- [`SECURITY.md`](SECURITY.md) — vulnerability disclosure policy
- [`docs/security-checklist.md`](docs/security-checklist.md) — pre-release security checklist
- [`docs/secure-storage-guide.md`](docs/secure-storage-guide.md) — Keychain and secure storage architecture

---

## Testing

The test suite covers **40 tests** across unit and UI layers.

```bash
# Run all tests
bundle exec fastlane test

# Run via xcodebuild directly
xcodebuild test \
  -scheme ExpenseMy \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  CODE_SIGNING_ALLOWED=NO
```

**What is covered:**
- `CategoryClassifierTests` — merchant-to-category mapping rules
- `TransactionModelTests` — SwiftData model creation and field validation
- `ExpenseMyTests` — SMS parser extraction (amount, merchant, bank, date, type)
- `ExpenseMyUITests` — launch and navigation smoke tests

Code coverage is generated automatically on every CI run and uploaded as an artifact.

---

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the full contribution guide, branch naming conventions, PR requirements (CHANGELOG update, SwiftLint passing, tests green), and the Danger-enforced PR checklist.

---

## Release Process

ExpenseMy uses semantic versioning (`MAJOR.MINOR.PATCH`) and a fully automated release pipeline.

1. Merge to `main` → automatic TestFlight beta deploy
2. Tag `vX.Y.Z` → automatic GitHub Release with changelog notes
3. Manual App Store submission via `bundle exec fastlane release`

See [`docs/release-process.md`](docs/release-process.md) for the complete step-by-step guide including hotfix workflows.

---

## Future Roadmap

- ML-based transaction categorization (replace regex with on-device Core ML model)
- Budget goals with overspend alerts
- Spending predictions and trend analysis
- Cloud sync (iCloud or custom backend)
- Export reports (CSV, PDF)
- Multi-bank intelligence improvements

---

## Team

| Name | Role | Responsibilities |
|---|---|---|
| **Manan Gurung** | iOS Developer | UI, Core Logic, SwiftUI views, SMS parsing, SwiftData models |
| **Ashish Khatri** | DevOps Engineer | CI/CD pipelines, security scanning, Fastlane, testing infrastructure |

---

## License

MIT — see [LICENSE](LICENSE) for details.
