# Contributing to ExpenseMy

Thank you for taking the time to contribute. This guide covers everything you need to get up and running.

---

## Prerequisites

| Tool | Minimum Version |
|------|----------------|
| macOS | 14.0 (Sonoma) |
| Xcode | 16.0 |
| SwiftLint | 0.57.0 |

Install SwiftLint via Homebrew:

```bash
brew install swiftlint
```

---

## Setup

```bash
git clone https://github.com/Mannagurung121/ExpenseMy.git
cd ExpenseMy
open ExpenseMy.xcodeproj
```

No additional dependency installation is required — the project currently has no Swift Package Manager dependencies.

---

## Running SwiftLint Locally

Run from the project root before every commit:

```bash
swiftlint lint
```

The project configuration is in `.swiftlint.yml`. Fix all errors and warnings before opening a PR. Autocorrect where safe:

```bash
swiftlint --fix
```

---

## Running Tests

Use `xcodebuild` from the project root:

```bash
# Unit tests
xcodebuild test \
  -project ExpenseMy.xcodeproj \
  -scheme ExpenseMy \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -resultBundlePath TestResults.xcresult

# UI tests
xcodebuild test \
  -project ExpenseMy.xcodeproj \
  -scheme ExpenseMy \
  -testPlan ExpenseMyUITests \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'
```

All tests must pass before a PR is merged.

---

## Branch Naming Convention

| Prefix | Use for |
|--------|---------|
| `feature/` | New functionality |
| `fix/` | Bug fixes |
| `chore/` | Maintenance, tooling, CI |
| `security/` | Security-related changes |
| `docs/` | Documentation only |

Examples: `feature/ml-categorization`, `fix/sms-parser-crash`, `security/keychain-migration`

---

## Commit Message Format

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short summary>

[optional body]

[optional footer(s)]
```

**Allowed types:**

| Type | Use for |
|------|---------|
| `feat` | A new feature |
| `fix` | A bug fix |
| `chore` | Tooling, CI, build changes |
| `docs` | Documentation only |
| `security` | Security hardening or vulnerability fix |
| `test` | Adding or updating tests |
| `refactor` | Code restructuring without behavior change |

**Examples:**

```
feat(parser): add HDFC credit card SMS pattern
fix(dashboard): correct monthly total for partial months
security(storage): migrate sensitive keys to Keychain
docs(contributing): add xcodebuild test instructions
```

---

## PR Process

1. Branch off `main` using the naming convention above.
2. Make your changes, keeping commits atomic and well-described.
3. Run SwiftLint and fix all issues.
4. Run the test suite and confirm it passes.
5. Update `CHANGELOG.md` under `[Unreleased]`.
6. Open a PR — the pull request template will guide the rest.
7. At least one approving review is required before merge.
8. The PR author merges after approval (squash preferred for feature branches).

---

## Code Review Requirements

- All checklist items in the PR template must be ticked.
- SwiftLint CI must be green.
- No new warnings introduced without justification.
- Security-labeled PRs require review from the project security contact before merge.

---

## Questions?

Open a [discussion](https://github.com/Mannagurung121/ExpenseMy/discussions) or reach out via a GitHub issue.
