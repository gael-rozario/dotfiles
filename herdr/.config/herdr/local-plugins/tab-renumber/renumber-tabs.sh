#!/usr/bin/env bash
# Renumber "<n>:<name>" tab labels in every workspace so <n> matches the tab's position.
# Tabs without a "<n>:" prefix (named by hand) are left alone. Runs from the tab-renumber plugin's
# tab.created / tab.closed / tab.moved hooks and from scripts/new-wt.sh.
set -uo pipefail

PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
herdr="${HERDR_BIN_PATH:-herdr}"

# group_by is stable, so tabs keep their display order within each workspace.
"$herdr" tab list 2>/dev/null | jq -r '
  .result.tabs | group_by(.workspace_id)[] | to_entries[]
  | select(.value.label | test("^[0-9]+:"))
  | "\(.key + 1):\(.value.label | sub("^[0-9]+:"; ""))" as $want
  | select($want != .value.label)
  | [.value.tab_id, $want] | @tsv' |
  while IFS=$'\t' read -r id want; do
    "$herdr" tab rename "$id" "$want" >/dev/null 2>&1 || true
  done
