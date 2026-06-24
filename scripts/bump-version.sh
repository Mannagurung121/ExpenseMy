#!/usr/bin/env bash
# bump-version.sh — Bump the project version and update CHANGELOG.md.
#
# Usage:
#   ./scripts/bump-version.sh patch    # 1.2.3 → 1.2.4
#   ./scripts/bump-version.sh minor    # 1.2.3 → 1.3.0
#   ./scripts/bump-version.sh major    # 1.2.3 → 2.0.0
#
# This script ONLY edits CHANGELOG.md and prints the git commands to run.
# It does NOT execute any git commands itself, so you stay in full control.

set -euo pipefail

# ─── 1. Validate argument ────────────────────────────────────────────────────

BUMP_TYPE="${1:-}"

if [[ -z "$BUMP_TYPE" ]]; then
  echo "ERROR: Missing argument. Usage: $0 <major|minor|patch>" >&2
  exit 1
fi

if [[ "$BUMP_TYPE" != "major" && "$BUMP_TYPE" != "minor" && "$BUMP_TYPE" != "patch" ]]; then
  echo "ERROR: Argument must be one of: major, minor, patch (got: '$BUMP_TYPE')" >&2
  exit 1
fi

# ─── 2. Verify CHANGELOG.md exists and has an [Unreleased] section ───────────

CHANGELOG="CHANGELOG.md"

if [[ ! -f "$CHANGELOG" ]]; then
  echo "ERROR: $CHANGELOG not found. Run this script from the repo root." >&2
  exit 1
fi

if ! grep -q "^## \[Unreleased\]" "$CHANGELOG"; then
  echo "ERROR: No '## [Unreleased]' section found in $CHANGELOG." >&2
  exit 1
fi

# Check that [Unreleased] has actual content (not just empty sub-headings).
UNRELEASED_CONTENT=$(awk \
  '/^## \[Unreleased\]/{found=1; next} found && /^## \[/{exit} found{print}' \
  "$CHANGELOG" | grep -v '^\s*$' | grep -v '^###' || true)

if [[ -z "$UNRELEASED_CONTENT" ]]; then
  echo "ERROR: The [Unreleased] section is empty. Add your changes before bumping." >&2
  exit 1
fi

# ─── 3. Determine the current latest version from git tags ──────────────────

# git describe returns the most recent tag reachable from HEAD.
# If the repo has no tags yet we fall back to 0.0.0.
if LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null); then
  # Strip a leading 'v' if present (e.g. v1.2.3 → 1.2.3)
  CURRENT_VERSION="${LATEST_TAG#v}"
else
  echo "No existing tags found — starting from 0.0.0"
  CURRENT_VERSION="0.0.0"
fi

echo "Current version: ${CURRENT_VERSION}"

# ─── 4. Parse MAJOR.MINOR.PATCH and compute the next version ─────────────────

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Validate that all three components are integers
for PART in "$MAJOR" "$MINOR" "$PATCH"; do
  if ! [[ "$PART" =~ ^[0-9]+$ ]]; then
    echo "ERROR: Could not parse version '${CURRENT_VERSION}' as MAJOR.MINOR.PATCH" >&2
    exit 1
  fi
done

case "$BUMP_TYPE" in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
echo "New version:     ${NEW_VERSION}"

# ─── 5. Build the new CHANGELOG content ──────────────────────────────────────

TODAY=$(date +%Y-%m-%d)

# Extract the current [Unreleased] block (everything up to the next ## header).
UNRELEASED_BLOCK=$(awk \
  '/^## \[Unreleased\]/{found=1; next} found && /^## \[/{exit} found{print}' \
  "$CHANGELOG")

# Build the replacement: a fresh empty [Unreleased] section, followed by the
# new versioned section carrying the content that was in [Unreleased].
NEW_UNRELEASED="## [Unreleased]

### Added

### Changed

### Fixed

### Security

---

## [${NEW_VERSION}] - ${TODAY}
${UNRELEASED_BLOCK}"

# Use awk to splice the new content into the file:
#   - When we hit the "## [Unreleased]" line, emit our replacement block
#     and set a flag to skip lines until the next "## [" header.
#   - Once we hit that next header, stop skipping and resume normal output.
TMP=$(mktemp)
awk \
  -v new_block="$NEW_UNRELEASED" \
  '
  /^## \[Unreleased\]/ {
    print new_block
    skip = 1
    next
  }
  skip && /^## \[/ {
    skip = 0
  }
  !skip { print }
  ' \
  "$CHANGELOG" > "$TMP"

mv "$TMP" "$CHANGELOG"

echo ""
echo "Updated ${CHANGELOG} — moved [Unreleased] content under [${NEW_VERSION}] - ${TODAY}"
echo ""

# ─── 6. Print the git commands to run (do NOT execute them) ──────────────────

echo "════════════════════════════════════════════════════"
echo "  Run the following commands to publish the release:"
echo "════════════════════════════════════════════════════"
echo ""
echo "  git add ${CHANGELOG}"
echo "  git commit -m \"chore: release ${NEW_VERSION}\""
echo "  git tag v${NEW_VERSION}"
echo "  git push origin main --tags"
echo ""
echo "After pushing the tag, GitHub Actions (release.yml) will automatically:"
echo "  • Create a GitHub Release with the extracted changelog notes"
echo "  • Upload any build artifacts"
echo "════════════════════════════════════════════════════"
