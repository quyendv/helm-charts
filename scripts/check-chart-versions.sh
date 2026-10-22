#!/usr/bin/env bash
#
# For every chart changed relative to a base ref, require that:
#   1. Chart.yaml's version is higher than on the base ref, and
#   2. CHANGELOG.md has a "## [<version>]" section for it.
# Changes limited to docs and test fixtures (README.md, CHANGELOG.md,
# examples/, ci/, tests/) do not need a release.
#
# Usage: scripts/check-chart-versions.sh <base-ref>   (e.g. origin/main)
set -euo pipefail

base="${1:?usage: $0 <base-ref>}"
status=0

# newer <old> <new>: succeed when <new> is a higher SemVer than <old>. sort -V
# alone ranks 2.0.0-rc.1 above 2.0.0, so the pre-release part is handled here.
newer() {
  local old="$1" new="$2" old_core="${1%%-*}" new_core="${2%%-*}"
  [ "$old" = "$new" ] && return 1
  if [ "$old_core" != "$new_core" ]; then
    [ "$(printf '%s\n%s\n' "$old_core" "$new_core" | sort -V | tail -1)" = "$new_core" ]
    return
  fi
  [ "$new" = "$new_core" ] && return 0 # release after its pre-release
  [ "$old" = "$old_core" ] && return 1 # pre-release after the release
  [ "$(printf '%s\n%s\n' "$old" "$new" | sort -V | tail -1)" = "$new" ]
}

charts="$(git diff --name-only "$base"...HEAD -- charts/ \
  | grep -Ev '^charts/[^/]+/(README\.md|CHANGELOG\.md|examples/|ci/|tests/)' \
  | cut -d/ -f2 | sort -u || true)"

for chart in $charts; do
  dir="charts/$chart"
  [ -f "$dir/Chart.yaml" ] || continue # chart removed
  new="$(awk '/^version:/ {print $2; exit}' "$dir/Chart.yaml")"
  old="$(git show "$base:$dir/Chart.yaml" 2>/dev/null | awk '/^version:/ {print $2; exit}' || true)"

  if [ -n "$old" ] && ! newer "$old" "$new"; then
    echo "::error file=$dir/Chart.yaml::$chart changed but its version was not bumped ($old -> $new)"
    status=1
  fi
  if ! grep -q "^## \[$new\]" "$dir/CHANGELOG.md" 2>/dev/null; then
    echo "::error file=$dir/CHANGELOG.md::$chart $new has no \"## [$new]\" section in CHANGELOG.md"
    status=1
  fi
  [ "$status" -eq 0 ] && echo "$chart: ${old:-new chart} -> $new, changelog entry found"
done

[ -n "$charts" ] || echo "No chart changes that need a release."
exit "$status"
