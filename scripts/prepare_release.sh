#!/usr/bin/env bash
# Bumps the version in pubspec.yaml and changelog.dart, then prints
# suggested kChangelog entries pulled from conventional commits since
# the last git tag.
#
# Usage:
#   ./scripts/prepare_release.sh <new_version>
#
# Example:
#   ./scripts/prepare_release.sh 0.2.0

set -euo pipefail

NEW_VERSION=${1:?"Usage: $0 <new_version>  (e.g. 0.2.0)"}

# ── Update pubspec.yaml ───────────────────────────────────────────────────────
sed -i "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml
echo "✔ pubspec.yaml → $NEW_VERSION"

# ── Update kAppVersion in changelog.dart ─────────────────────────────────────
sed -i "s/const String kAppVersion = '.*'/const String kAppVersion = '$NEW_VERSION'/" lib/data/changelog.dart
echo "✔ changelog.dart kAppVersion → $NEW_VERSION"

# ── Collect conventional commits since last tag ───────────────────────────────
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -n "$LAST_TAG" ]; then
  COMMITS=$(git log "${LAST_TAG}..HEAD" --oneline --no-merges 2>/dev/null || echo "")
else
  COMMITS=$(git log --oneline --no-merges -30 2>/dev/null || echo "")
fi

FEATURE_ENTRIES=""
FIX_ENTRIES=""

while IFS= read -r line; do
  # Strip the short hash prefix
  MSG="${line#* }"
  if [[ "$MSG" == feat:* ]]; then
    DESC="${MSG#feat: }"
    FEATURE_ENTRIES+="    ChangeEntry(ChangeType.feature, '${DESC}'),\n"
  elif [[ "$MSG" == fix:* ]]; then
    DESC="${MSG#fix: }"
    FIX_ENTRIES+="    ChangeEntry(ChangeType.fix, '${DESC}'),\n"
  fi
done <<< "$COMMITS"

# ── Print suggested kChangelog block ─────────────────────────────────────────
echo ""
echo "── Suggested kChangelog entry ───────────────────────────────────────────"
echo "  '$NEW_VERSION': ["
if [ -n "$FEATURE_ENTRIES" ]; then
  printf "%b" "$FEATURE_ENTRIES"
fi
if [ -n "$FIX_ENTRIES" ]; then
  printf "%b" "$FIX_ENTRIES"
fi
if [ -z "$FEATURE_ENTRIES" ] && [ -z "$FIX_ENTRIES" ]; then
  echo "    // No feat:/fix: commits found since ${LAST_TAG:-the beginning}."
  echo "    // Add entries manually."
fi
echo "  ],"
echo "─────────────────────────────────────────────────────────────────────────"
echo ""
echo "Paste the block above into kChangelog in lib/data/changelog.dart,"
echo "polish the descriptions, then commit and open a PR to main."
