# Changelog

All notable changes to ExpenseMy will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added

### Changed

### Fixed

### Security

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
