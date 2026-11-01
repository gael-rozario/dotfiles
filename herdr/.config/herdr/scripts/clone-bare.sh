#!/usr/bin/env bash
# Clone bare popup: prompt for a GridX repo name, bare-clone git@github.com:GridX/<repo> into
# ~/workspace/github.com/gridx/<repo>.nvim (with origin/* tracking), add a worktree for the default branch at
# <root>/<default> and add a shell tab in it to the active workspace.
set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"
ws="${HERDR_ACTIVE_WORKSPACE_ID:?no active herdr workspace}"
repos="$HOME/workspace/github.com/gridx"

fail() {
  printf '\n%s\n[press any key]' "$*"
  read -rsn1 2>/dev/null || read -r _
  exit 1
}

read -rp 'GridX repo: ' repo
# Accept "name", "GridX/name", "name.git" or "name.nvim".
repo=$(printf '%s' "$repo" | tr -d '[:space:]')
repo="${repo#GridX/}"; repo="${repo#gridx/}"; repo="${repo%.git}"; repo="${repo%.nvim}"
[ -n "$repo" ] || exit 0

root="$repos/$repo.nvim"
[ ! -e "$root" ] || fail "already exists: $root"
url="git@github.com:GridX/$repo"

printf 'cloning %s -> %s\n' "$url" "$root"
mkdir -p "$repos"
git clone --bare "$url" "$root" || fail "clone failed: $url"
cd "$root"

# Bare clones have no fetch refspec (so no origin/* refs and no upstreams); add it so worktrees can pull/track.
git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
out=$(git fetch --quiet origin 2>&1) || fail "$out"
git remote set-head origin --auto >/dev/null 2>&1 || true

default=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||') \
  || default=""
[ -n "$default" ] || default=$(git symbolic-ref --short HEAD 2>/dev/null) || default=main

path="$root/$default"
out=$(git worktree add "$path" "$default" 2>&1) || fail "$out"
out=$(git -C "$path" branch --set-upstream-to="origin/$default" 2>&1) || fail "$out"

# The label starts as "0:..." so the zsh tab-name hook treats it as numbered; the real index is set below.
out=$("$herdr" tab create --workspace "$ws" --cwd "$path" --label "0:$repo" --no-focus 2>&1) || fail "$out"
tab=$(jq -er '.result.tab.tab_id' <<<"$out") || fail "no tab in: $out"

/bin/bash ~/.config/herdr/local-plugins/tab-renumber/renumber-tabs.sh
out=$("$herdr" tab focus "$tab" 2>&1) || fail "$out"
