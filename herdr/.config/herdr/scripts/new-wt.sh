#!/usr/bin/env bash
# New worktree popup: pick a bare repo under ~/workspace/github.com/gridx (fzf), a type (fzf), an optional
# work-name and an optional source branch. Creates <type>/<workspace>[-<work-name>] (dir and branch) under the
# repo root and adds a shell tab in the new worktree to the active workspace.
set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"
ws="${HERDR_ACTIVE_WORKSPACE_ID:?no active herdr workspace}"
repos="$HOME/workspace/github.com/gridx"

fail() {
  printf '\n%s\n[press any key]' "$*"
  read -rsn1 2>/dev/null || read -r _
  exit 1
}

# Branch names are built from the active workspace's label (as timew does); spaces and slashes become dashes.
out=$("$herdr" workspace get "$ws" 2>&1) || fail "$out"
wsname=$(jq -r '.result.workspace.label // empty' <<<"$out" | tr -s '[:space:]/' '-' | sed 's/^-//; s/-$//')
[ -n "$wsname" ] || fail "active workspace has no label"

# Only bare repos for now (worktrees live under the repo root as <type>/<name>).
repo=$(
  for d in "$repos"/*/; do
    if [ "$(git -C "$d" rev-parse --is-bare-repository 2>/dev/null)" = true ]; then basename "$d"; fi
  done | fzf --prompt='repo> ' --header="new worktree for workspace: $wsname"
) || exit 0
root="$repos/$repo"

type=$(printf '%s\n' fix feat docs chore refactor test | fzf --no-sort --prompt='type> ' --header="$repo") || exit 0

cd "$root"
default=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||') \
  || default=""
[ -n "$default" ] || default=$(git symbolic-ref --short HEAD 2>/dev/null) || default=main

clear
printf '%s  %s/%s\n\n' "$repo" "$type" "$wsname"
read -rp 'work-name (optional): ' work
read -rp "source [$default]: " src
src="${src:-$default}"

branch="$type/$wsname${work:+-$work}"
git check-ref-format --branch "$branch" >/dev/null 2>&1 || fail "invalid branch name: $branch"
path="$root/$branch"
[ ! -e "$path" ] || fail "already exists: $path"

# An existing branch is checked out as-is; the source only applies to a new branch.
if git show-ref --verify --quiet "refs/heads/$branch"; then
  out=$(git worktree add "$path" "$branch" 2>&1) || fail "$out"
else
  # Bare clones have no fetch refspec, so fetch the source explicitly; prefer origin over a stale local branch.
  printf 'fetching origin/%s...\n' "$src"
  git fetch --quiet origin "+refs/heads/$src:refs/remotes/origin/$src" 2>/dev/null || true
  if git show-ref --verify --quiet "refs/remotes/origin/$src"; then
    base="origin/$src"
  elif git show-ref --verify --quiet "refs/heads/$src"; then
    base="$src"
  else
    fail "source branch not found: $src"
  fi
  out=$(git worktree add --no-track -b "$branch" "$path" "$base" 2>&1) || fail "$out"
fi

# Every bare repo keeps a worktree for its default branch at <root>/<default>; create it if missing.
main="$root/$default"
if [ ! -e "$main" ]; then
  out=$(git worktree add "$main" "$default" 2>&1) || fail "$out"
fi

# herdr only nests worktree subworkspaces under the repo's own parent workspace, so instead add a shell tab in
# the new worktree to the workspace we were in.
name="${branch#*/}"
# The label starts as "0:..." so the zsh tab-name hook treats it as numbered; the real index is set below.
out=$("$herdr" tab create --workspace "$ws" --cwd "$path" --label "0:$name" --no-focus 2>&1) || fail "$out"
tab=$(jq -er '.result.tab.tab_id' <<<"$out") || fail "no tab in: $out"

/bin/bash ~/.config/herdr/local-plugins/tab-renumber/renumber-tabs.sh
out=$("$herdr" tab focus "$tab" 2>&1) || fail "$out"
