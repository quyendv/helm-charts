#!/usr/bin/env bash
#
# Rewrite the body of every existing GitHub release of a chart from its
# CHANGELOG.md (same format as new releases). Versions without a changelog
# section are reported and left untouched. Safe to re-run.
#
# Usage: scripts/backfill-release-notes.sh <chart-dir> [--dry-run]
set -euo pipefail

chart_dir="${1:?usage: $0 <chart-dir> [--dry-run]}"
dry_run="${2:-}"
chart="$(awk '/^name:/ {print $2; exit}' "$chart_dir/Chart.yaml")"
here="$(cd "$(dirname "$0")" && pwd)"
notes_file="$(mktemp)"
trap 'rm -f "$notes_file"' EXIT

gh release list --limit 1000 --json tagName --jq '.[].tagName' | grep "^$chart-" | while read -r tag; do
  version="${tag#"$chart"-}"
  if ! "$here/release-notes.sh" "$chart_dir" "$version" > "$notes_file" 2>/dev/null; then
    echo "skip   $tag (no CHANGELOG section)"
    continue
  fi
  if [ "$dry_run" = "--dry-run" ]; then
    echo "would  $tag ($(wc -l < "$notes_file") lines)"
  else
    gh release edit "$tag" --notes-file "$notes_file" > /dev/null
    echo "update $tag"
  fi
done
