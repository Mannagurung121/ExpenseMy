# ExpenseMy — DevOps Overview

**Author:** Ashish Khatri ([@asisqt](https://github.com/asisqt)) — DevOps Engineer

This document covers the complete DevOps strategy for ExpenseMy: a native iOS app with no backend server. Every tool, workflow, and decision is documented here so the pipeline can be understood, reproduced, or handed off without tribal knowledge.

---

## Strategy Overview

ExpenseMy is a purely client-side iOS app. There is no API server, no database to deploy, and no infrastructure to provision. DevOps work for a project like this focuses on four areas:

1. **Code quality gates** — prevent bad code from reaching `main`
2. **Automated distribution** — build, sign, and ship to TestFlight on every merge without manual steps
3. **Security posture** — scan for secrets, vulnerable dependencies, and misconfigurations in CI
4. **Observability** — crash reporting and usage analytics via Firebase, integrated without compromising the no-credentials-in-repo constraint

The entire pipeline runs on GitHub Actions (free minutes for public repos) using macOS-hosted runners provided by GitHub, with Fastlane as the iOS-specific build orchestration layer.

---

## CI/CD Pipeline Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│  Developer pushes to feature branch and opens PR                 │
└──────────────────────────────┬───────────────────────────────────┘
                               │ PR event
          ┌────────────────────┼──────────────────────┐
          │                    │                      │
    ┌─────▼──────┐    ┌────────▼───────┐    ┌────────▼───────┐
    │ SwiftLint  │    │ Security Scan  │    │ Danger Review  │
    │ (swiftlint │    │ (security-scan │    │ (danger.yml)   │
    │  .yml)     │    │  .yml)         │    │                │
    └─────┬──────┘    └────────┬───────┘    └────────┬───────┘
          │                    │                      │
          │           ┌────────▼───────┐    ┌────────▼───────┐
          │           │ TruffleHog     │    │ PR size check  │
          │           │ SPM audit      │    │ CHANGELOG check│
          │           │ Sensitive file │    │ via Dangerfile │
          │           │ check          │    └────────────────┘
          │           └────────────────┘
          │
    ┌─────▼──────┐    ┌─────────────────┐
    │   Build    │    │ Version Check   │
    │ (build.yml)│    │ (version-check  │
    │            │    │  .yml)          │
    └─────┬──────┘    └─────────────────┘
          │            CHANGELOG.md must
          │            be updated in PR
    ┌─────▼──────┐
    │    Test    │
    │ (test.yml) │
    │ unit + UI  │
    │ + coverage │
    └─────┬──────┘
          │
          │  PR merged to main
          ▼
    ┌─────────────┐
    │    Beta     │
    │ (beta.yml)  │
    │ TestFlight  │
    └─────┬───────┘
          │
          │  Developer pushes v*.*.* tag
          ▼
    ┌─────────────┐
    │   Release   │
    │ (release.yml│
    │ GitHub      │
    │ Release     │
    └─────────────┘
          │
          │  Manual step
          ▼
    bundle exec fastlane release
    (App Store submission)
```

---

## Workflow Reference Table

| Workflow | File | Trigger | Runner | What It Does | Secrets Required |
|---|---|---|---|---|---|
| SwiftLint | `swiftlint.yml` | Push + PR to `main` | `macos-15` | Installs SwiftLint via Homebrew, runs `swiftlint lint` with GitHub Actions reporter so violations annotate the PR diff | None |
| Build | `build.yml` | Push + PR to `main` | `macos-15` | Runs SwiftLint as a prerequisite job, then resolves SPM packages and builds for iPhone 16 simulator with code signing disabled; uploads build log on failure | None |
| Test | `test.yml` | Push + PR to `main` | `macos-15` | Runs unit tests (`ExpenseMyTests`) with code coverage enabled, then UI tests (`ExpenseMyUITests`); uploads `.xcresult` bundle; prints per-target coverage percentage | None |
| Security Scan | `security-scan.yml` | PR to `main` | `ubuntu-latest` | Three parallel jobs: (1) TruffleHog scans git history for verified secrets, (2) parses `Package.resolved` and lists SPM dependencies for manual CVE review, (3) walks full git history for tracked sensitive files (plist, p12, mobileprovision, .env) | None |
| Danger PR Review | `danger.yml` | PR to `main` | `ubuntu-latest` | Runs the `Dangerfile` via Bundler; checks PR size, description completeness, and other team-defined PR hygiene rules; posts inline comments | `DANGER_GITHUB_API_TOKEN` |
| Version Check | `version-check.yml` | PR to `main` | `ubuntu-latest` | Fails the PR if `CHANGELOG.md` was not modified, or if the `[Unreleased]` section contains no real content | None |
| Beta (TestFlight) | `beta.yml` | Push to `main` (merge) | `macos-15` | Syncs certificates via Fastlane Match, increments build number to `GITHUB_RUN_NUMBER`, builds a signed IPA with `gym`, uploads to TestFlight with `pilot`; posts a build-info comment on the merge commit | `APPLE_ID`, `APP_SPECIFIC_PASSWORD`, `TEAM_ID`, `MATCH_PASSWORD`, `MATCH_GIT_URL`, `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` |
| Release | `release.yml` | Push of `v*.*.*` tag | `macos-15` | Extracts the version from the tag, parses the matching `CHANGELOG.md` section for release notes, creates a GitHub Release with those notes and any `.ipa`/`.xcarchive` artifacts; a `notify` job prints a release summary | `GITHUB_TOKEN` (automatic) |

---

## Fastlane Integration

Fastlane is the iOS build orchestration layer that wraps `xcodebuild` with a higher-level Ruby DSL. All lanes are defined in `fastlane/Fastfile`.

| Lane | CI Workflow | Command | What It Does |
|---|---|---|---|
| `test` | `test.yml` (optional) | `bundle exec fastlane test` | Runs `ExpenseMyTests` on the iPhone 16 simulator with code coverage; outputs `test-results.xml` |
| `build` | `build.yml` (optional) | `bundle exec fastlane build` | Simulator build, no signing; wraps the same `xcodebuild build` command CI uses |
| `beta` | `beta.yml` | `bundle exec fastlane beta` | Match → increment build number → `gym` (signed IPA) → `pilot` (TestFlight upload) |
| `release` | Manual | `bundle exec fastlane release` | Match → `gym` (Release config) → `deliver` (App Store submission with metadata) |

Certificate management uses **Fastlane Match** (`fastlane/Matchfile`) to store encrypted certificates and provisioning profiles in a private Git repository. CI runners pull certificates at build time using `MATCH_PASSWORD` and `MATCH_GIT_URL` secrets — no certificates are ever stored in this repo.

---

## Security Posture

### What Is Automated on Every PR

| Control | Tool | Workflow |
|---|---|---|
| Secret detection in git history | TruffleHog `--only-verified` | `security-scan.yml` |
| SPM dependency inventory | Python script parsing `Package.resolved` | `security-scan.yml` |
| Sensitive file tracking check | `git log --full-history` pattern scan | `security-scan.yml` |
| Swift code style enforcement | SwiftLint (`.swiftlint.yml` ruleset) | `swiftlint.yml`, `build.yml` |
| PR hygiene and size review | Danger + `Dangerfile` | `danger.yml` |
| CHANGELOG enforcement | `awk` parse of `CHANGELOG.md` | `version-check.yml` |

### OWASP Mobile Top 10 Coverage

| OWASP ID | Risk | Control in ExpenseMy |
|---|---|---|
| M1 | Improper Credential Usage | No credentials in source; all secrets in GitHub Actions secrets and Apple Keychain |
| M2 | Inadequate Supply Chain Security | SPM dependency audit on every PR; manual CVE review recommended |
| M7 | Insufficient Binary Protections | Firebase dSYMs uploaded to Crashlytics; Release builds with symbols included |
| M9 | Insecure Data Storage | `KeychainService` with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`; no sensitive data in UserDefaults |
| M10 | Insufficient Cryptography | Keychain handles encryption at rest via AES-256 and Secure Enclave; no custom crypto |

### Keychain Architecture

All sensitive values (API keys, user tokens, identifiers) are stored via `KeychainService` with the following guarantees:

- Encrypted at rest with AES-256
- Protected by device passcode / biometrics via the Secure Enclave
- `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — excluded from iCloud and iTunes backups
- Scoped to service name `com.expensemy.keychain` to avoid collisions with other apps

See [`docs/secure-storage-guide.md`](secure-storage-guide.md) for the full design.

---

## Monitoring and Observability

### Crash Reporting — Firebase Crashlytics
`CrashlyticsService` wraps Crashlytics and is called at app startup. Non-fatal errors are logged with typed context (error type, affected screen, user action). Release builds include dSYM files so Crashlytics can symbolicate stack traces.

### Usage Analytics — Firebase Analytics
`AnalyticsService` logs named events with typed parameters. Events are defined in [`docs/analytics-events.md`](analytics-events.md). The wrapper is conditionally compiled so it compiles to a no-op without `GoogleService-Info.plist`.

### Remote Feature Flags — Firebase Remote Config
`RemoteConfigService` provides typed accessors for feature flags. This allows enabling or disabling features (e.g., a new parser, a UI experiment) in production without an App Store update.

### Build Metadata on Merge Commits
`beta.yml` posts a build metadata comment to every merge commit that triggers a TestFlight deploy. The comment includes marketing version, build number, commit SHA, and a link to the workflow run. This creates a durable audit trail linking every TestFlight build to the exact commit that produced it.

---

## Infrastructure Decisions Log

### GitHub Actions over CircleCI / Bitrise
GitHub Actions was chosen because:
- The repo is already on GitHub — no third-party OAuth or webhook configuration required
- GitHub-hosted macOS runners are available on the free tier for public repositories
- YAML workflows live in the repo alongside the code they test; no external dashboard needed
- `macos-15` runners include Xcode 16.2 pre-installed, matching the project's required Xcode version

Bitrise offers more iOS-specific features but costs money beyond the free tier and requires managing a separate platform. CircleCI macOS support is paid. For an open-source iOS project, GitHub Actions is the obvious choice.

### Fastlane for iOS Build Orchestration
Fastlane is the de facto standard for iOS CI automation. It provides:
- `match` — encrypted certificate management in a private Git repo (no manual provisioning)
- `gym` — wrapper around `xcodebuild archive` + export with sane defaults
- `pilot` — TestFlight upload via App Store Connect API
- `deliver` — App Store submission with metadata management

The alternative (raw `xcodebuild` commands) requires managing code signing manually and duplicating logic across every script. Fastlane's abstraction is well-maintained, widely documented, and familiar to iOS teams.

### TruffleHog for Secret Detection
TruffleHog scans git history (not just the current HEAD) using entropy analysis and pattern matching against known secret formats. The `--only-verified` flag reduces false positives by testing detected credentials against their respective APIs before reporting them. This is a higher signal-to-noise approach compared to simpler regex-only tools like `git-secrets`.

### Danger for PR Review Automation
Danger enforces PR hygiene rules that are awkward to express as CI pass/fail checks — things like PR description completeness, file change scope, and team-specific conventions. The `Dangerfile` is version-controlled in the repo and easy to extend. It runs on `ubuntu-latest` (not macOS) to save macOS runner minutes.

---

## Metrics and KPIs

The pipeline tracks the following automatically:

| Metric | Where | How |
|---|---|---|
| Build success rate | GitHub Actions → `build.yml` | Pass/fail badge; build log artifact on failure |
| Test count | `test.yml` output | xcodebuild reports test count per target |
| Code coverage | `test.yml` → `.xcresult` artifact | `xccov` generates per-target coverage % printed in job log |
| Security scan results | `security-scan.yml` | Job pass/fail; explicit PASS/FAIL lines per check |
| TestFlight build number | `beta.yml` commit comment | `GITHUB_RUN_NUMBER` used as build number; commit comment records it |
| Changelog discipline | `version-check.yml` | PR blocked if `CHANGELOG.md` not updated |

---

## Cost Analysis

All tools in the pipeline are **zero-cost** for this project:

| Tool / Service | Tier Used | Cost |
|---|---|---|
| GitHub Actions | Free tier for public repos (unlimited minutes on `ubuntu-latest`; 2,000 min/month on macOS — sufficient for this project's PR volume) | $0 |
| GitHub-hosted macOS runners | `macos-15` included in free tier for public repos | $0 |
| Fastlane | Open source (MIT) | $0 |
| TruffleHog | Open source; GitHub Actions integration free | $0 |
| Danger | Open source (MIT) | $0 |
| SwiftLint | Open source (MIT) | $0 |
| Firebase (Crashlytics, Analytics, Remote Config) | Spark (free) plan — no billing required for these products | $0 |
| App Store Connect / TestFlight | Included in Apple Developer Program ($99/year, paid by the team) | $0 incremental |
| Fastlane Match certificate repo | Private GitHub repo (free) | $0 |

The only non-free cost is the Apple Developer Program membership, which is required regardless of DevOps tooling choices.
