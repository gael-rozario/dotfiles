#!/usr/bin/env bash
# sessionx-style picker for herdr: existing workspaces first, then zoxide directories.
# Picking a workspace focuses it. Picking a directory focuses the workspace whose label
# matches the directory name, or creates one there.
set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"
workspaces=$("$herdr" workspace list | jq -r '.result.workspaces[] | "\(.workspace_id)\t\(.label)"')

pick=$(
  {
    printf '%s\n' "$workspaces" | awk -F'\t' 'NF {print "ws\t" $1 "\t● " $2}'
    zoxide query -l | sed "s|^$HOME|~|" | awk '{print "dir\t\t" $0}'
  } | fzf --delimiter='\t' --with-nth=3 --no-sort --prompt='workspace> ' \
        --header='enter: focus / create' \
        --preview='p={3}; p=${p/#\~/$HOME}; [ -d "$p" ] && eza -1 --icons=never "$p" 2>/dev/null || ls "$p" 2>/dev/null' \
        --preview-window='right,40%'
) || exit 0

kind=$(cut -f1 <<<"$pick")
if [ "$kind" = ws ]; then
  "$herdr" workspace focus "$(cut -f2 <<<"$pick")" >/dev/null
  exit 0
fi

dir=$(cut -f3 <<<"$pick")
dir="${dir/#\~/$HOME}"
name=$(basename "$dir")

existing=$(printf '%s\n' "$workspaces" | awk -F'\t' -v n="$name" '$2 == n {print $1; exit}')
if [ -n "$existing" ]; then
  "$herdr" workspace focus "$existing" >/dev/null
else
  "$herdr" workspace create --cwd "$dir" --label "$name" --focus >/dev/null
fi
