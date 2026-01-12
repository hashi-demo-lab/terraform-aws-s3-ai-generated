#!/bin/bash
# Setup required GitHub labels for CI/CD workflows
#
# Usage: ./setup_labels.sh [REPO]
# Example: ./setup_labels.sh owner/repo-name

set -e

REPO="${1:-$(gh repo view --json nameWithOwner -q '.nameWithOwner')}"

echo "Setting up labels for: $REPO"

# Semver labels
gh label create "semver:patch" --color "0E8A16" --description "Bug fix release (x.x.PATCH)" --repo "$REPO" 2>/dev/null || \
  gh label edit "semver:patch" --color "0E8A16" --description "Bug fix release (x.x.PATCH)" --repo "$REPO"

gh label create "semver:minor" --color "1D76DB" --description "Feature release (x.MINOR.0)" --repo "$REPO" 2>/dev/null || \
  gh label edit "semver:minor" --color "1D76DB" --description "Feature release (x.MINOR.0)" --repo "$REPO"

gh label create "semver:major" --color "B60205" --description "Breaking change release (MAJOR.0.0)" --repo "$REPO" 2>/dev/null || \
  gh label edit "semver:major" --color "B60205" --description "Breaking change release (MAJOR.0.0)" --repo "$REPO"

# Status labels
gh label create "breaking-change" --color "D93F0B" --description "Contains breaking changes" --repo "$REPO" 2>/dev/null || \
  gh label edit "breaking-change" --color "D93F0B" --description "Contains breaking changes" --repo "$REPO"

gh label create "ci-skip" --color "EDEDED" --description "Skip CI checks" --repo "$REPO" 2>/dev/null || \
  gh label edit "ci-skip" --color "EDEDED" --description "Skip CI checks" --repo "$REPO"

gh label create "needs-tests" --color "FBCA04" --description "Requires additional tests" --repo "$REPO" 2>/dev/null || \
  gh label edit "needs-tests" --color "FBCA04" --description "Requires additional tests" --repo "$REPO"

gh label create "security" --color "D73A4A" --description "Security-related changes" --repo "$REPO" 2>/dev/null || \
  gh label edit "security" --color "D73A4A" --description "Security-related changes" --repo "$REPO"

echo "✅ Labels configured successfully"
echo ""
echo "Available semver labels:"
echo "  - semver:patch  (green)  - Bug fixes"
echo "  - semver:minor  (blue)   - New features"
echo "  - semver:major  (red)    - Breaking changes"
