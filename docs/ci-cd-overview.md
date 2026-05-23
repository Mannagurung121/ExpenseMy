# CI/CD Overview — ExpenseMy

This document describes every automated workflow that runs on GitHub Actions, how they relate to each other, and how the Fastlane lanes integrate with CI.

---

## Workflow files

### `.github/workflows/swiftlint.yml`

| Property | Value |
|---|---|
| **Trigger** | Push to `main`, pull request to `main` |
| **Runner** | `macos-15` |
| **Purpose** | Enforce Swift style and conventions |

**Jobs:**

1. **swiftlint** — Installs SwiftLint via Homebrew and runs `swiftlint lint --reporter github-actions-logging`. Violations are annotated directly on the PR diff.

**Secrets required:** none

---

### `.github/workflows/security-scan.yml`

| Property | Value |
|---|---|
| **Trigger** | Push to `main`, pull request to `main` |
| **Runner** | `macos-15` (or `ubuntu-latest` depending on scan type) |
| **Purpose** | Detect secrets, audit dependencies, verify `.gitignore` coverage |

**Jobs:**

1. **secret-detection** — Scans the repository for accidentally committed credentials.
2. **dependency-audit** — Checks Swift Package dependencies for known vulnerabilities.
3. **gitignore-check** — Verifies that build artifacts and secrets are covered by `.gitignore`.

**Secrets required:** `SONAR_TOKEN` (if SonarCloud is enabled), `DANGER_GITHUB_API_TOKEN` (if Danger JS is integrated).

---

### `.github/workflows/build.yml`

| Property | Value |
|---|---|
| **Trigger** | Push to `main`, pull request to `main` |
| **Runner** | `macos-15` |
| **Purpose** | Verify the project compiles cleanly |

**Jobs:**

#### 1. `lint` (runs first)

| Step | Command |
|---|---|
| Checkout | `actions/checkout@v4` |
| Install SwiftLint | `brew install swiftlint` |
| Run SwiftLint | `swiftlint lint --reporter github-actions-logging` |

#### 2. `build` (runs after `lint`)

| Step | Command |
|---|---|
| Checkout | `actions/checkout@v4` |
| Select Xcode 16.2 | `sudo xcode-select -s /Applications/Xcode_16.2.app/Contents/Developer` |
| Show Xcode version | `xcodebuild -version` |
| Resolve packages | `xcodebuild -resolvePackageDependencies -scheme ExpenseMy` |
| Build | `xcodebuild build -scheme ExpenseMy -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO -quiet` |
| Upload log (failure only) | `actions/upload-artifact@v4` — artifact name `build-log`, retained 7 days |

**Dependency chain:** `build` job will not start until `lint` passes (`needs: [lint]`).

**Secrets required:** none

---

### `.github/workflows/test.yml`

| Property | Value |
|---|---|
| **Trigger** | Push to `main`, pull request to `main` |
| **Runner** | `macos-15` |
| **Purpose** | Run unit tests, UI tests, and report code coverage |

**Jobs:**

#### `test`

| Step | Command |
|---|---|
| Checkout | `actions/checkout@v4` |
| Select Xcode 16.2 | `sudo xcode-select -s /Applications/Xcode_16.2.app/Contents/Developer` |
| Show Xcode version | `xcodebuild -version` |
| Unit tests | `xcodebuild test -scheme ExpenseMy -destination '...' -only-testing:ExpenseMyTests CODE_SIGNING_ALLOWED=NO -resultBundlePath TestResults.xcresult -enableCodeCoverage YES` |
| UI tests | `xcodebuild test -scheme ExpenseMy -destination '...' -only-testing:ExpenseMyUITests CODE_SIGNING_ALLOWED=NO` |
| Upload results | `actions/upload-artifact@v4` — artifact name `TestResults`, path `TestResults.xcresult`, retained 14 days |
| Coverage summary | `xcrun xccov view --report TestResults.xcresult --json` piped to a Python script that prints `ExpenseMy` target line coverage percentage |

**Note:** `test.yml` is independent — it does not have a cross-workflow `needs` dependency on `build.yml`. Both run in parallel on push/PR. GitHub's branch protection rules can be configured to require both to pass before merge.

**Secrets required:** none

---

## Dependency chain summary

```
swiftlint.yml ─────── (independent)
security-scan.yml ─── (independent)

build.yml:
  lint ──► build

test.yml:
  test  (unit) ──► test (UI) ──► upload results ──► coverage summary
```

For a pull request to be merge-ready, all four workflow files must pass. Configure this under **Settings › Branches › Branch protection rules** by requiring status checks: `SwiftLint`, `lint`, `Build`, and `test`.

---

## How to read CI results on a PR

1. Open the pull request on GitHub.
2. Scroll to the **Checks** section at the bottom of the PR page.
3. Each workflow appears as a named check. Click **Details** to see individual job logs.
4. SwiftLint violations appear as inline annotations on the **Files changed** tab.
5. Test results and build logs are available as **Artifacts** in the workflow run summary (click the workflow name, then scroll to **Artifacts**).
6. Code coverage percentage is printed in the `Generate code coverage summary` step log.

---

## Fastlane integration

Fastlane lanes are defined in `fastlane/Fastfile`. They can be called from GitHub Actions workflows or run locally.

| Lane | What it does | CI use case |
|---|---|---|
| `test` | Runs `ExpenseMyTests` unit tests on simulator | Can replace the raw `xcodebuild test` step |
| `build` | Unsigned simulator build | Smoke-check compilation |
| `beta` | Signed IPA → TestFlight | Triggered manually or on merge to `main` |
| `release` | Signed IPA → App Store submission | Triggered manually before a release |

The `beta` and `release` lanes require Apple credentials passed as environment variables. In GitHub Actions these come from repository secrets (see `docs/secrets-setup.md`).

**Example CI step calling a Fastlane lane:**
```yaml
- name: Upload beta to TestFlight
  env:
    APPLE_ID: ${{ secrets.APPLE_ID }}
    TEAM_ID: ${{ secrets.TEAM_ID }}
    APP_SPECIFIC_PASSWORD: ${{ secrets.APP_SPECIFIC_PASSWORD }}
    MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
    MATCH_GIT_URL: ${{ secrets.MATCH_GIT_URL }}
  run: bundle exec fastlane beta
```
