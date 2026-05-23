# Fastlane — ExpenseMy

Fastlane automates building, testing, and releasing the ExpenseMy iOS app.

## Prerequisites

```bash
gem install bundler
bundle install        # installs fastlane and plugins from Gemfile
```

---

## Lanes

### `test`

Runs the `ExpenseMyTests` unit test suite against the iPhone 16 simulator.

**Credentials required:** none  
**Usage:**
```bash
bundle exec fastlane test
```

### `build`

Produces an unsigned simulator build using `xcodebuild`. Useful for verifying the project compiles before investing in signing setup.

**Credentials required:** none  
**Usage:**
```bash
bundle exec fastlane build
```

### `beta`

Builds a signed IPA and uploads it to TestFlight for internal testing.

**Credentials required:**

| Variable | Description |
|---|---|
| `APPLE_ID` | Your Apple ID email address |
| `TEAM_ID` | Your 10-character Apple Developer team ID |
| `APP_SPECIFIC_PASSWORD` | App-specific password from [appleid.apple.com](https://appleid.apple.com) |
| `MATCH_PASSWORD` | Passphrase that encrypts the Match certificates repository |
| `MATCH_GIT_URL` | HTTPS URL of your private certificates repository |

**Usage:**
```bash
export APPLE_ID="you@example.com"
export TEAM_ID="XXXXXXXXXX"
export APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
export MATCH_PASSWORD="your-match-passphrase"
export MATCH_GIT_URL="https://github.com/your-org/certificates.git"

bundle exec fastlane beta
```

### `release`

Builds a signed IPA and submits it to the App Store for review via `deliver`.  
Before using this lane, populate `fastlane/metadata/` and `fastlane/screenshots/` (see [deliver docs](https://docs.fastlane.tools/actions/deliver/)).

**Credentials required:** same as `beta`  
**Usage:**
```bash
bundle exec fastlane release
```

---

## Code Signing with Match

[Match](https://docs.fastlane.tools/actions/match/) stores all certificates and provisioning profiles encrypted in a private Git repository.

### First-time setup

1. Create a **private** GitHub repository to store certificates (e.g., `your-org/certificates`).
2. Run Match in setup mode (this generates certificates and pushes them):
   ```bash
   bundle exec fastlane match init           # creates fastlane/Matchfile
   bundle exec fastlane match development    # generate development cert + profile
   bundle exec fastlane match appstore       # generate distribution cert + profile
   ```
3. Save the passphrase you choose as `MATCH_PASSWORD` in GitHub Secrets.

### Revoking and regenerating

```bash
bundle exec fastlane match nuke distribution   # revoke distribution cert (destructive!)
bundle exec fastlane match appstore            # regenerate
```

---

## GitHub Actions Secrets

Add these secrets under **Settings › Secrets and variables › Actions** in your GitHub repository:

| Secret | Used by |
|---|---|
| `APPLE_ID` | `beta`, `release` lanes |
| `APP_SPECIFIC_PASSWORD` | `beta`, `release` lanes |
| `TEAM_ID` | `beta`, `release` lanes |
| `MATCH_PASSWORD` | `beta`, `release` lanes |
| `MATCH_GIT_URL` | `beta`, `release` lanes |

See [`docs/secrets-setup.md`](../docs/secrets-setup.md) for step-by-step instructions on obtaining each value.

---

## Running locally vs. CI

The lanes are identical locally and in CI. In CI the environment variables come from GitHub Secrets; locally export them in your shell or use a `.env.beta` file (add to `.gitignore`).
