#!/usr/bin/env bash
# herdr capture (prefix+shift+c) and filing (prefix+i) popups exist exactly once,
# herdr's built-in prefix+c (new_tab) is not shadowed, the config validates,
# and an empty capture title creates nothing.
set -uo pipefail
DOT=${DOTFILES:-$HOME/.dotfiles}
CFG=$DOT/herdr/.config/herdr/config.toml
rc=0; err() { echo "  $*" >&2; rc=1; }
herdr config check >/dev/null 2>&1 || err "herdr config check failed"
PY=(uv run --no-project --offline --python 3.12 python)  # tomllib needs >= 3.11
cmd_for() { "${PY[@]}" -c 'import sys,tomllib; c=tomllib.load(open(sys.argv[1],"rb")); m=[k for k in c["keys"].get("command",[]) if k["key"]==sys.argv[2]]; print(len(m)); print(m[0]["command"] if m else "")' "$CFG" "$1"; }
CAP=prefix+shift+c
[[ $(cmd_for prefix+c | head -1) == 0 ]] || err "prefix+c is herdr's built-in new_tab; do not bind a custom command to it"
for k in $CAP prefix+i; do
  n=$(cmd_for "$k" | head -1); [[ $n == 1 ]] || err "$k bound $n times (want 1)"
  grep -nE "^\s*[a-z_]+\s*=\s*\"$k\"" "$CFG" | grep -v 'key = ' >/dev/null && err "$k also used by a built-in binding"
done
c=$(cmd_for $CAP | tail -n +2)
[[ $c == *"$HOME/.local/bin/nn"* || $c == *"~/.local/bin/nn"* ]] || err "capture must call ~/.local/bin/nn"
[[ $(cmd_for prefix+i | tail -n +2) == *"/.local/bin/sb-review"* ]] || err "filing must call ~/.local/bin/sb-review"
# empty_title: run the capture command with a stub nn under a fake HOME
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/home/.local/bin" "$tmp/v/0_inbox"
printf '#!/bin/sh\necho called >> "%s"\n' "$tmp/calls" > "$tmp/home/.local/bin/nn"; chmod +x "$tmp/home/.local/bin/nn"
if [[ -n $c ]]; then
  printf '\n' | HOME="$tmp/home" SB_VAULT="$tmp/v" bash -c "$c" >/dev/null 2>&1
  [[ ! -e $tmp/calls ]] || err "empty_title: nn was invoked"
  [[ -z $(find "$tmp/v/0_inbox" -type f) ]] || err "empty_title: a file was created"
  printf 'Go slice copy\n' | HOME="$tmp/home" SB_VAULT="$tmp/v" bash -c "$c" >/dev/null 2>&1
  [[ -e $tmp/calls ]] || err "capture: nn not invoked for a real title"
fi
exit $rc
