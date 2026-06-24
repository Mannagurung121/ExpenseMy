# Release Process

This document describes how ExpenseMy is versioned, how betas reach TestFlight, and how production releases are published to GitHub.

---

## Table of Contents

1. [Version Numbering](#version-numbering)
2. [Pre-release Checklist](#pre-release-checklist)
3. [Bump the Version](#bump-the-version)
4. [Beta Pipeline (automatic)](#beta-pipeline-automatic)
5. [Production Release (tag-triggered)](#production-release-tag-triggered)
6. [Rollback Procedure](#rollback-procedure)
7. [Emergency Hotfix Workflow](#emergency-hotfix-workflow)
8. [Release Flow Diagram](#release-flow-diagram)

---

## Version Numbering

ExpenseMy follows [Semantic Versioning](https://semver.org/) — `MAJOR.MINOR.PATCH`:

| Part    | When to bump                                                  | Example            |
|---------|---------------------------------------------------------------|--------------------|
| `PATCH` | Bug fixes, typo corrections, minor internal improvements      | `1.2.3` → `1.2.4` |
| `MINOR` | New user-visible features, backwards-compatible changes       | `1.2.3` → `1.3.0` |
| `MAJOR` | Breaking changes, large redesigns, incompatible data changes  | `1.2.3` → `2.0.0` |

When `MINOR` is bumped, `PATCH` resets to `0`. When `MAJOR` is bumped, both `MINOR` and `PATCH` reset to `0`.

---

## Pre-release Checklist

Complete every item before creating a release tag:

- [ ] All CI checks green on `main` (build, test, SwiftLint, security-scan, Danger)
- [ ] The `[Unreleased]` section in `CHANGELOG.md` contains entries for every user-facing change
- [ ] All PRs for this release have been merged to `main`
- [ ] Code has been reviewed and approved
- [ ] The latest TestFlight beta has been smoke-tested
- [ ] App Store Connect metadata (screenshots, description) updated if needed for a public release

---

## Bump the Version

Use `scripts/bump-version.sh` to update `CHANGELOG.md` and get the exact git commands to run.

### Examples

```bash
# Bug fix release
./scripts/bump-version.sh patch

# New feature release
./scripts/bump-version.sh minor

# Breaking change or major redesign
./scripts/bump-version.sh major
```

### What the script does

1. Reads the latest git tag to determine the current version (defaults to `0.0.0` if no tags exist).
2. Calculates the next version by incrementing the appropriate component.
3. Moves the `[Unreleased]` section content in `CHANGELOG.md` under a new versioned header dated today.
4. Adds a fresh empty `[Unreleased]` section at the top of the changelog.
5. **Prints** (but does **not** run) the git commands you need to execute.

### After running the script

The script prints something like:

```
Run the following commands to publish the release:

  git add CHANGELOG.md
  git commit -m "chore: release 1.3.0"
  git tag v1.3.0
  git push origin main --tags
```

Copy-paste and run those commands. Pushing the tag triggers `release.yml` automatically.

---

## Beta Pipeline (automatic)

**Every merge to `main` automatically deploys to TestFlight.**

The workflow at `.github/workflows/beta.yml`:

1. Checks out the code on a macOS 15 runner with Xcode 16.2.
2. Runs `bundle exec fastlane beta`, which builds, signs (via Match), and uploads to TestFlight.
3. Posts a commit comment with the version and build number so you can trace any TestFlight build back to its exact commit.

### Required GitHub Secrets

| Secret                                      | Purpose                                      |
|---------------------------------------------|----------------------------------------------|
| `APPLE_ID`                                  | Apple ID email for App Store Connect         |
| `APP_SPECIFIC_PASSWORD`                     | App-specific password for that Apple ID      |
| `TEAM_ID`                                   | Apple Developer Team ID                      |
| `MATCH_PASSWORD`                            | Password to decrypt the Match certificate repo |
| `MATCH_GIT_URL`                             | Git URL of the Match certificates repo       |
| `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` | Same as `APP_SPECIFIC_PASSWORD` (Fastlane env var name) |

See `docs/secrets-setup.md` for instructions on creating and storing these secrets.

---

## Production Release (tag-triggered)

The workflow at `.github/workflows/release.yml` fires whenever a tag matching `v*.*.*` is pushed.

Steps performed automatically:

1. Extracts the version number from the tag (strips the `v` prefix).
2. Parses `CHANGELOG.md` to find the notes for that version.
3. Creates a GitHub Release with those notes as the body.
4. Uploads any `.ipa` or `.xcarchive` artifacts present in the workspace.
5. Runs the `notify` job, which logs a summary (extend it to post a Slack/Discord message).

---

## Rollback Procedure

Use this when a release is discovered to be broken after the tag is pushed.

> **Warning:** force-pushing a tag rewrites shared history. Coordinate with the team first.

```bash
# 1. Revert the bad commit on main
git revert <bad-commit-sha>
git push origin main

# 2. Delete the bad tag locally and remotely
git tag -d v1.3.0
git push origin :refs/tags/v1.3.0

# 3. Re-tag the previous good commit (if you want to restore a prior release)
git tag v1.2.9 <last-good-sha>
git push origin v1.2.9
```

The previous TestFlight build remains available to testers; App Store Connect keeps all historical builds.

---

## Emergency Hotfix Workflow

Use this when `main` already contains unreleased work that must not ship, but a critical bug in production needs a fix immediately.

```bash
# 1. Branch from the production tag, not from main
git checkout -b hotfix/crash-on-launch v1.3.0

# 2. Apply the minimal fix
#    (make your code changes here)

# 3. Commit
git add .
git commit -m "fix: crash on launch when transaction list is empty"

# 4. Update CHANGELOG.md manually:
#    Move the fix entry under a new [1.3.1] section with today's date.

# 5. Bump patch version and tag
./scripts/bump-version.sh patch
# Follow the printed git commands:
git add CHANGELOG.md
git commit -m "chore: release 1.3.1"
git tag v1.3.1
git push origin hotfix/crash-on-launch --tags

# 6. Merge the hotfix back to main
git checkout main
git merge hotfix/crash-on-launch
git push origin main

# 7. Clean up
git branch -d hotfix/crash-on-launch
```

Pushing `v1.3.1` triggers `release.yml` to publish the GitHub Release automatically.

---

## Release Flow Diagram

```
Developer                  GitHub                    Apple
─────────────────────────────────────────────────────────────────────────

  Feature branch
       │
       ▼
  Open PR ──────────────► version-check.yml
                           • CHANGELOG.md modified?
                           • [Unreleased] has content?
                              │
                        ┌─────┴──────┐
                       FAIL         PASS
                        │            │
                   Fix & push      Merge to main ──────────────────────►
                                        │
                                        ▼
                                   beta.yml (push to main)
                                   • Xcode 16.2 build
                                   • fastlane beta
                                   • Upload to TestFlight ──────────────► TestFlight
                                   • Comment on commit                    (testers)
                                        │
                             (manual: run bump-version.sh,
                              then git push --tags)
                                        │
                                        ▼
                                   release.yml (tag push v*.*.*)
                                   • Extract changelog
                                   • Create GitHub Release
                                   • Upload artifacts
                                   • Notify job (Slack/Discord)
                                        │
                                        ▼
                                   GitHub Release page
                                   (changelog + artifacts)
```
