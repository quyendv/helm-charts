#!/usr/bin/env bash
#
# Print the GitHub release body for one chart version: that version's section
# of the chart's CHANGELOG.md, followed by install instructions and a link to
# the diff against the previous release of the same chart.
#
# Usage: scripts/release-notes.sh <chart-dir> [version]
#   version defaults to the one in <chart-dir>/Chart.yaml.
# Env:   GITHUB_REPOSITORY (owner/repo) for links; falls back to the origin remote.
# Fails when CHANGELOG.md has no section for the version, so a release can
# never go out without notes.
set -euo pipefail

chart_dir="${1:?usage: $0 <chart-dir> [version]}"
chart="$(awk '/^name:/ {print $2; exit}' "$chart_dir/Chart.yaml")"
version="${2:-$(awk '/^version:/ {print $2; exit}' "$chart_dir/Chart.yaml")}"
changelog="$chart_dir/CHANGELOG.md"

# The section body: lines after "## [<version>]" up to the next "## [" heading.
notes="$(awk -v v="$version" '
  index($0, "## [" v "]") == 1 { found = 1; next }
  found && /^## \[/ { exit }
  found { print }
' "$changelog")"
if [ -z "$(printf '%s' "$notes" | tr -d '[:space:]')" ]; then
  echo "error: $changelog has no \"## [$version]\" section" >&2
  exit 1
fi

repo="${GITHUB_REPOSITORY:-$(git remote get-url origin | sed -E 's#^.*github\.com[^:/]*[:/]##; s#\.git$##')}"
owner="${repo%%/*}"
name="${repo#*/}"
tag="$chart-$version"

# Previous release of this chart: the highest existing tag below this version.
prev="$(git tag --list "$chart-*" | sed "s/^$chart-//" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
  | { cat; echo "$version"; } | sort -V -u | awk -v v="$version" '$0 == v { print p; exit } { p = $0 }')"

# Trim leading/trailing blank lines from the section.
printf '%s\n' "$notes" | sed -e '/./,$!d' | sed -e ':a' -e '/^\n*$/{$d;N;ba' -e '}'
cat <<NOTES

## Install

\`\`\`bash
helm repo add $owner https://$owner.github.io/$name
helm repo update
helm upgrade --install my-release $owner/$chart --version $version
\`\`\`
NOTES
if [ -n "$prev" ]; then
  printf '\n**Full diff**: https://github.com/%s/compare/%s-%s...%s\n' "$repo" "$chart" "$prev" "$tag"
fi
