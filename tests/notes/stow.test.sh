#!/usr/bin/env bash
# The note scripts are stow-managed symlinks into ~/.dotfiles/bin; ~/.local/bin
# itself stays a real directory and unrelated tools are left alone.
set -uo pipefail
DOT=${DOTFILES:-$HOME/.dotfiles}
BIN=$HOME/.local/bin
rc=0
err() { echo "  $*" >&2; rc=1; }
[[ -d $BIN && ! -L $BIN ]] || err "$BIN must be a real directory"
for s in nn sb-review sb-lint sb-index sb-archive notes-sync; do
  [[ -L $BIN/$s ]] || { err "$s is not a symlink"; continue; }
  [[ $(readlink -f "$BIN/$s") == "$DOT/bin/.local/bin/$s" ]] || err "$s resolves to $(readlink -f "$BIN/$s")"
  [[ -x $BIN/$s ]] || err "$s not executable"
done
for o in no nwn tb-index tb-lint tb-review; do
  [[ -e $BIN/$o ]] || continue
  case $(readlink -f "$BIN/$o") in "$DOT"/*) err "$o must not be stow-managed";; esac
done
[[ ! -e $BIN/README ]] || err "README must not be linked into $BIN"
exit $rc
