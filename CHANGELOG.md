# Changelog

All notable changes to ExpenseMy will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added

- CI/CD pipeline of 8 GitHub Actions workflows (build, test, SwiftLint, security scan, Danger, version check, beta/TestFlight, release)
- Fastlane integration with `test`, `build`, `beta`, and `release` lanes plus Fastlane Match certificate management
- Firebase service wrappers — Crashlytics, Analytics, and Remote Config — conditionally compiled so the app builds without the SDK
- Apple Keychain security layer (`KeychainService`) with hardware-backed, backup-excluded storage
- `SecureStorageService` enforcing the sensitive (Keychain) vs. non-sensitive (UserDefaults) storage boundary
- `NetworkSecurityService` — certificate-pinning URLSession delegate, `SecureAPIClient` with signed async GET/POST, ready for future cloud sync
- `LoggingService` — structured logging over Apple's unified logging (`os.Logger`) with categories, redaction, and Crashlytics forwarding
- Apple Privacy Manifest (`ExpenseMy/PrivacyInfo.xcprivacy`) declaring tracking, collected data types, and required-reason APIs
- 52 automated tests — 40 unit and 12 UI tests
- Danger automated PR review via version-controlled `Dangerfile`
- SonarCloud integration — `sonar-project.properties`, `sonar.yml` workflow with xcresult→generic-coverage conversion, and setup guide
- Comprehensive documentation suite — DevOps overview, architecture, CI/CD, release process, secrets/Firebase setup, privacy compliance, infrastructure ADRs, and a pre-push checklist
- Environment configuration templates — `.env.example` and `GoogleService-Info.plist.example`

### Changed

### Fixed

### Security

- TruffleHog secret scanning of full git history on every PR
- OWASP Mobile Top 10 security audit (`docs/security-checklist.md`)
- Certificate pinning infrastructure (`NetworkSecurityService`) for future networked endpoints
- Privacy compliance documentation (`docs/privacy-compliance.md`) covering the Apple Privacy Manifest and GDPR/CCPA posture

---

## [0.1.0] - 2026-05-19

### Added

- NLP / regex-based SMS parser that extracts amount, merchant, bank, and debit/credit type from bank messages
- Automatic transaction categorization (food, shopping, transport, utilities, etc.)
- SwiftData-backed transaction persistence
- Home dashboard with analytics summary and category-wise spend charts (Charts framework)
- Monthly expense visualization
- Transaction list view with filter pills (by date range and category)
- Transaction detail view
- iOS Widgets via WidgetKit (`SpendWidget`, `SpendWidgetBundle`) showing current spend at a glance
- Share Extension (`ExpenseMyShare`) — share any bank SMS directly to ExpenseMy from the Messages app
- App Groups entitlement wiring between main app and Share Extension for shared data access
- `AddTransactionView` for manual transaction entry
- Parsed preview screen (`ParesdPreview`) showing parser output before saving
- Reusable component library: `StatCard`, `FilterPillView`, `EmptyStateView`
- SwiftLint integration with project-level `.swiftlint.yml` configuration
- GitHub Actions CI workflow for automated SwiftLint checks on every PR

[Unreleased]: https://github.com/Mannagurung121/ExpenseMy/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Mannagurung121/ExpenseMy/releases/tag/v0.1.0
