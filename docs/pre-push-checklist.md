# Pre-Push & Pre-Release Checklist — ExpenseMy

Run through this before pushing to `main`, opening a release PR, or submitting to
the App Store. It verifies CI wiring, secret hygiene, and submission readiness.

---

## 1. CI workflows and their required secrets

ExpenseMy has **9 GitHub Actions workflows**. Confirm each is present and that
its secrets are configured (see §3).

| Workflow | File | Trigger | Secrets required |
|---|---|---|---|
| SwiftLint | `.github/workflows/swiftlint.yml` | push + PR to `main` | none |
| Build | `.github/workflows/build.yml` | push + PR to `main` | none |
| Test | `.github/workflows/test.yml` | push + PR to `main` | none |
| Security Scan | `.github/workflows/security-scan.yml` | PR to `main` | none |
| Danger PR Review | `.github/workflows/danger.yml` | PR to `main` | `DANGER_GITHUB_API_TOKEN` |
| Version Check | `.github/workflows/version-check.yml` | PR to `main` | none |
| SonarCloud | `.github/workflows/sonar.yml` | push + PR to `main` | `SONAR_TOKEN`, `GITHUB_TOKEN` (auto) |
| Beta (TestFlight) | `.github/workflows/beta.yml` | push to `main` | `APPLE_ID`, `APP_SPECIFIC_PASSWORD`, `TEAM_ID`, `MATCH_PASSWORD`, `MATCH_GIT_URL`, `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` |
| Release | `.github/workflows/release.yml` | push of `v*.*.*` tag | `GITHUB_TOKEN` (auto) |

---

## 2. Verifications

### 2.1 No hardcoded secrets in any workflow

Every workflow must read sensitive values from `${{ secrets.NAME }}`, never
inline. Verify:

```bash
# Should return NOTHING. Any hit is a hardcoded credential to remove.
grep -rEn '(password|token|api[_-]?key|secret)\s*[:=]\s*["'"'"']?[A-Za-z0-9/_-]{12,}' \
  .github/workflows/ || echo "OK: no inline secrets in workflows"

# Confirm secret references use the secrets context.
grep -rn 'secrets\.' .github/workflows/
```

- [ ] No inline credentials in any workflow file
- [ ] All credentials referenced via `${{ secrets.* }}`

### 2.2 .gitignore covers all sensitive files

Confirm `.gitignore` ignores at least: `.env`, `secrets/`,
`GoogleService-Info.plist`, `*.xcarchive`, `*.ipa`, `*.p12`,
`*.mobileprovision`, `xcuserdata/`.

```bash
for p in .env GoogleService-Info.plist secrets/ "*.ipa" "*.xcarchive" xcuserdata/; do
  git check-ignore -q "$p" && echo "ignored: $p" || echo "NOT IGNORED: $p"
done
```

- [ ] `.env` ignored (only `.env.example` is committed)
- [ ] `GoogleService-Info.plist` ignored (only `GoogleService-Info.plist.example` committed)
- [ ] `secrets/`, `*.ipa`, `*.xcarchive` ignored
- [ ] No `*.p12` / `*.mobileprovision` tracked

### 2.3 No xcuserdata committed

`xcuserdata/` holds per-user Xcode state and must never be tracked.

```bash
# Should return NOTHING.
git ls-files | grep -i xcuserdata || echo "OK: no xcuserdata tracked"
```

> NOTE: the repo currently contains `*.xcuserdata*` paths from before this rule
> was enforced. If the command above prints anything, untrack it with
> `git rm -r --cached '*xcuserdata*'` in a dedicated cleanup PR.

- [ ] `git ls-files | grep xcuserdata` returns nothing

### 2.4 No tracked sensitive files in history

The `security-scan.yml` workflow enforces this on every PR, but verify locally:

```bash
git log --all --full-history --name-only --format="" \
  -- '*/GoogleService-Info.plist' '*.env' '.env' '*.p12' '*.mobileprovision' '*.key' \
  | sort -u | grep -v '^$' || echo "OK: no sensitive files in history"
```

- [ ] No `GoogleService-Info.plist`, `.env`, `.p12`, `.mobileprovision`, `.key` in git history

### 2.5 Placeholder values are documented

All `REPLACE_ME` / template placeholders must be intentional and documented.

```bash
grep -rn "REPLACE_ME" . --include="*.example" --include="*.properties" \
  --include="Fastfile" --include="Appfile" 2>/dev/null
```

Expected placeholder locations (all documented):

| Placeholder | File | Documented in |
|---|---|---|
| `REPLACE_ME` Firebase keys | `GoogleService-Info.plist.example` | `docs/firebase-setup.md` |
| `your_*` / `xxxx` values | `.env.example` | `docs/secrets-setup.md` |
| `com.REPLACE_ME.ExpenseMy` | `fastlane/Fastfile` | `docs/release-process.md` |
| `Mannagurung121_ExpenseMy` keys | `sonar-project.properties` | `docs/sonarcloud-setup.md` |

- [ ] Every `REPLACE_ME` is in a `.example`/template file and documented

---

## 3. GitHub Secrets to configure

Add these under repo **Settings → Secrets and variables → Actions**
(see `docs/secrets-setup.md` for how to obtain each):

- [ ] `APPLE_ID`
- [ ] `APP_SPECIFIC_PASSWORD`
- [ ] `TEAM_ID`
- [ ] `MATCH_PASSWORD`
- [ ] `MATCH_GIT_URL`
- [ ] `DANGER_GITHUB_API_TOKEN`
- [ ] `SONAR_TOKEN`

> `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` holds the same value as
> `APP_SPECIFIC_PASSWORD` (Fastlane reads that specific variable name).
> `GITHUB_TOKEN` is injected automatically and needs no setup.

---

## 4. Pre-App Store checklist

- [ ] **Privacy Manifest** present and on the app target —
      `ExpenseMy/PrivacyInfo.xcprivacy` (validate: `plutil -lint ExpenseMy/PrivacyInfo.xcprivacy`)
- [ ] **App Privacy** questionnaire in App Store Connect matches the manifest
      (see `docs/privacy-compliance.md`)
- [ ] **Entitlements reviewed** — `ExpenseMy.entitlements` and
      `ExpenseMyShare.entitlements` list only the App Group; no unused capabilities
      (`codesign -d --entitlements - ExpenseMy.app`)
- [ ] **Code signing configured** — Distribution certificate + App Store profile
      available via Fastlane Match (`bundle exec fastlane match appstore --readonly`)
- [ ] **Version bumped** — `MARKETING_VERSION` updated and `CHANGELOG.md`
      `[Unreleased]` section finalized (`version-check.yml` enforces the changelog)
- [ ] **dSYMs** uploaded to Crashlytics for symbolication (not shipped in the app)
- [ ] OWASP review items in `docs/security-checklist.md` triaged for the release

---

## 5. Test verification

The suite has **52 tests** total: **40 unit** + **12 UI**. Confirm all pass
locally (`bundle exec fastlane test`) and in the Test workflow before pushing.

### Unit tests — `ExpenseMyTests` (40)

| File | Tests |
|---|---|
| `ExpenseMyTests/ExpenseMyTests.swift` | 19 |
| `ExpenseMyTests/CategoryClassifierTests.swift` | 14 |
| `ExpenseMyTests/TransactionModelTests.swift` | 7 |

### UI tests — `ExpenseMyUITests` (12)

| File | Tests |
|---|---|
| `ExpenseMyUITests/ExpenseMyUITests.swift` | 8 |
| `ExpenseMyUITests/ExpenseMyUITestsLaunchTests.swift` | 4 |

```bash
# Re-count any time to keep this table honest:
for f in ExpenseMyTests/*.swift ExpenseMyUITests/*.swift; do
  printf "%-55s %s\n" "$f" "$(grep -cE 'func test' "$f")"
done
```

- [ ] All 40 unit tests pass
- [ ] All 12 UI tests pass
- [ ] Coverage report generated (`test.yml` / `sonar.yml`)
