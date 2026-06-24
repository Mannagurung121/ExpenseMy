# Infrastructure Decision Records — ExpenseMy

This is the Architecture Decision Records (ADR) log for ExpenseMy's
infrastructure, tooling, and platform choices. Each record captures the context
at decision time, the decision itself, and its consequences — so future
maintainers understand *why*, not just *what*.

Format: Title · Date · Status · Context · Decision · Consequences.
Status values: Proposed · Accepted · Superseded · Deprecated.

---

## ADR-001: GitHub Actions over CircleCI / Bitrise

- **Date:** 2026-05-19
- **Status:** Accepted

**Context.** ExpenseMy needs CI for linting, building, testing, security
scanning, and TestFlight distribution. The repo already lives on GitHub. Options
considered: GitHub Actions, CircleCI, Bitrise.

**Decision.** Use GitHub Actions with GitHub-hosted `macos-15` runners (Xcode
16.2 pre-installed) and `ubuntu-latest` for non-Xcode jobs.

**Consequences.**
- *Positive:* Free for public repos; workflows live beside the code; no
  third-party OAuth/webhooks; native PR status checks and annotations; macOS
  runners include the required Xcode version.
- *Negative:* macOS minutes are capped (2,000/month) and slower/costlier than
  Linux if the project goes private; vendor lock-in to GitHub's YAML and runner
  images.

---

## ADR-002: Fastlane for iOS CI

- **Date:** 2026-05-19
- **Status:** Accepted

**Context.** Signing, build-number management, and TestFlight/App Store upload
are tedious and error-prone with raw `xcodebuild`. We need a repeatable,
scriptable build orchestration layer.

**Decision.** Use Fastlane (`fastlane/Fastfile`) with lanes `test`, `build`,
`beta`, `release`, and Fastlane Match for certificate management.

**Consequences.**
- *Positive:* Industry standard; `match` handles signing/provisioning from an
  encrypted private repo; `gym`/`pilot`/`deliver` wrap archive/export/upload;
  logic is shared between local and CI runs.
- *Negative:* Ruby/Bundler toolchain to maintain; Fastlane release churn can
  break lanes; another abstraction layer to learn.

---

## ADR-003: TruffleHog for secret scanning

- **Date:** 2026-05-19
- **Status:** Accepted

**Context.** A financial app must never leak credentials into git history. We
need automated detection of committed secrets, including in past commits.

**Decision.** Run TruffleHog in `security-scan.yml` on every PR with
`--only-verified`, scanning full git history.

**Consequences.**
- *Positive:* Open source; official GitHub Action; scans history not just HEAD;
  `--only-verified` cuts false positives by validating findings against live
  APIs.
- *Negative:* `--only-verified` can miss inert-but-sensitive strings; depends on
  an external action pinned to `@main`; verification step adds PR latency.

---

## ADR-004: Danger for PR review

- **Date:** 2026-05-19
- **Status:** Accepted

**Context.** Some PR-hygiene rules (description completeness, change scope,
CHANGELOG updates) are awkward to express as pass/fail CI steps and better
surfaced as inline review comments.

**Decision.** Use Danger (Ruby) via a version-controlled `Dangerfile`, run in
`danger.yml` on `ubuntu-latest` using `DANGER_GITHUB_API_TOKEN`.

**Consequences.**
- *Positive:* Flexible, code-defined rules; posts inline PR comments; runs on
  cheap Linux runners; rules evolve with the team.
- *Negative:* Requires a GitHub token secret; Ruby dependency; overly strict
  rules can create review friction.

---

## ADR-005: Apple Keychain over third-party storage

- **Date:** 2026-05-19
- **Status:** Accepted

**Context.** Sensitive values (future auth tokens, user identifiers) must be
stored securely. Options: hand-rolled Keychain wrapper, a third-party Keychain
library, or UserDefaults (rejected outright).

**Decision.** Use a first-party `KeychainService` built on the Security
framework with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, fronted by
`SecureStorageService` to enforce the sensitive/non-sensitive boundary.

**Consequences.**
- *Positive:* Zero dependencies; hardware-backed (Secure Enclave) AES-256
  encryption; excluded from backups; satisfies OWASP M1/M9; no supply-chain risk.
- *Negative:* Must maintain the Security-framework boilerplate ourselves; the
  raw API is verbose and easy to misuse without the wrapper.

---

## ADR-006: Conditional compilation for Firebase

- **Date:** 2026-05-19
- **Status:** Accepted

**Context.** Firebase (Crashlytics/Analytics/Remote Config) is desired for
observability, but the app must build and run without the SDK or a
`GoogleService-Info.plist` — for contributors, CI, and unit tests.

**Decision.** Guard every Firebase service with `#if canImport(Firebase*)`,
providing console-logging stubs in the `#else` branch.

**Consequences.**
- *Positive:* No hard dependency; builds clean without secrets; tests run
  without Firebase; SDK can be added later with zero changes to call sites.
- *Negative:* Two code paths per service to keep in sync; stub behaviour differs
  from real behaviour, so integration must be verified on-device once linked.

---

## ADR-007: Regex over ML for SMS parsing (v1)

- **Date:** 2026-05-19
- **Status:** Accepted

**Context.** The core feature extracts amount, merchant, bank, and debit/credit
type from bank SMS. Options: a regex/rule engine or an on-device ML model.

**Decision.** Ship a regex-based parser (`SmsParser.swift`) for v1; gate any
future ML categorisation behind the `is_ml_categorization_enabled` Remote Config
flag.

**Consequences.**
- *Positive:* Simple, deterministic, debuggable; no model training, bundling, or
  inference cost; sufficient for the structured formats of Indian banks; easy to
  unit-test.
- *Negative:* Brittle to novel or changed SMS formats; patterns need maintenance;
  must guard against ReDoS (OWASP M4). Revisit with ML if format coverage stalls.

---

## ADR-008: SwiftData over Core Data

- **Date:** 2026-05-19
- **Status:** Accepted

**Context.** The app needs on-device persistence for transactions with SwiftUI
integration. Options: SwiftData or Core Data.

**Decision.** Use SwiftData (`@Model`, `modelContainer`) as the persistence
layer.

**Consequences.**
- *Positive:* Modern, Swift-native API; far less boilerplate; first-class SwiftUI
  integration via `@Query`; built on the proven Core Data stack.
- *Negative:* iOS 17+ minimum; younger API with sharper edges and fewer
  escape hatches than Core Data; no application-layer encryption by default
  (mitigated via file protection — see OWASP M9 in `docs/security-checklist.md`).
