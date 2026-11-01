#!/usr/bin/env bash
# Small prompt for a new git worktree: dir, branch, source. The worktree is created in the
# active pane's cwd and opened as two new tabs in the current workspace: claude and nvim.
set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"
ws="${HERDR_ACTIVE_WORKSPACE_ID:?no active herdr workspace}"

fail() {
  printf '\n%s\n[press any key]' "$*"
  read -rsn1 2>/dev/null || read -r _
  exit 1
}

cwd="${HERDR_ACTIVE_PANE_CWD:-$PWD}"
cd "$cwd"
git rev-parse --git-dir >/dev/null 2>&1 || fail "not a git repo: $cwd"

default=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||') \
  || default=""
[ -n "$default" ] || default=$(git symbolic-ref --short HEAD 2>/dev/null) || default=main

printf 'New worktree\n\n'
read -rp 'dir: ' dir
[ -n "$dir" ] || exit 0
read -rp "branch [$dir]: " branch
branch="${branch:-$dir}"
read -rp "source [$default]: " base
base="${base:-$default}"

path="$cwd/$dir"
# An existing branch is checked out as-is; the source only applies to a new branch.
if git show-ref --verify --quiet "refs/heads/$branch"; then
  out=$(git worktree add "$path" "$branch" 2>&1) || fail "$out"
else
  # Fall back to origin/<source> when there's no local branch of that name.
  if ! git show-ref --verify --quiet "refs/heads/$base" &&
     git show-ref --verify --quiet "refs/remotes/origin/$base"; then
    base="origin/$base"
  fi
  out=$(git worktree add -b "$branch" "$path" "$base" 2>&1) || fail "$out"
fi

# Tabs are named after the worktree so several worktrees can share one workspace.
name="${dir##*/}"
out=$("$herdr" tab create --workspace "$ws" --cwd "$path" --label "$name claude" --focus 2>&1) || fail "$out"
"$herdr" pane run "$(jq -r .result.root_pane.pane_id <<<"$out")" claude >/dev/null

out=$("$herdr" tab create --workspace "$ws" --cwd "$path" --label "$name nvim" --no-focus 2>&1) || fail "$out"
"$herdr" pane run "$(jq -r .result.root_pane.pane_id <<<"$out")" "vi ." >/dev/null
