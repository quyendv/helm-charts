#!/usr/bin/env bash
#
# Regenerate the "Available Charts" table in the root README.md from each
# chart's Chart.yaml (name / version / description). The table is written
# between the CHARTS_TABLE:START and CHARTS_TABLE:END markers so the rest of
# the README is left untouched. Pure awk/sed — no helm/node/yq dependency.
#
# Usage: scripts/gen-charts-index.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
README="$ROOT/README.md"
START="<!-- CHARTS_TABLE:START -->"
END="<!-- CHARTS_TABLE:END -->"

field() { # field <key> <file>
  awk -v k="$1" 'BEGIN{FS=":"} $1==k {sub(/^[^:]*:[[:space:]]*/,""); gsub(/^["'\'']|["'\'']$/,""); print; exit}' "$2"
}

rows=""
for cf in "$ROOT"/charts/*/Chart.yaml; do
  [ -f "$cf" ] || continue
  name="$(field name "$cf")"
  version="$(field version "$cf")"
  desc="$(field description "$cf")"
  rows+="| [${name}](./charts/${name}) | ${desc} | ${version} |"$'\n'
done

table="${START}
| Chart | Description | Version |
| ----- | ----------- | ------- |
${rows}${END}"

awk -v start="$START" -v end="$END" -v repl="$table" '
  index($0, start) { print repl; skip=1; next }
  index($0, end)   { skip=0; next }
  !skip            { print }
' "$README" > "$README.tmp" && mv "$README.tmp" "$README"

echo "Updated Available Charts table in README.md"
