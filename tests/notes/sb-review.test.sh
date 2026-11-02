#!/usr/bin/env bash
# sb-review's type menu: a number or an existing name picks a type; a new
# PascalCase name plus a one-line description adds a row to index.md's type
# table and files the note under it. Runs against a throwaway vault.
set -uo pipefail
DOT=${DOTFILES:-$HOME/.dotfiles}
export PATH="$DOT/bin/.local/bin:$PATH"
rc=0; err() { echo "  $*" >&2; rc=1; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
V="$tmp/vault"; export SB_VAULT="$V"

mkvault() {
  rm -rf "$V"; mkdir -p "$V/0_inbox" "$V/3_resources/hubs" "$V/3_resources/fact"
  cat > "$V/index.md" <<'EOF'
# Second Brain

## Ingestion workflow and note types

Intro prose.

| `type`         | Kind of content                                          |
|----------------|----------------------------------------------------------|
| `Fact`         | Short standalone reference (operators, shortcuts, …).    |
| `Hub`          | Topic anchor for `hubs:` links.                          |

To add a type, add a row here.

## Next section

Tail.
EOF
  cat > "$V/0_inbox/pasta.md" <<'EOF'
---
type:
description: How I make carbonara for two.
timestamp: '2026-11-03T00:00:00Z'
hubs: []
---

Body.
EOF
}

types_of() { awk '/^## Ingestion/{s=1; next} /^#/{s=0} s && /^\| `/{gsub(/`/,""); split($0,a,"|"); gsub(/ /,"",a[2]); if (a[2] != "type") print a[2]}' "$V/index.md"; }

# 1. new type: name, description, then destination
mkvault
printf 's\nRecipe\nA dish: ingredients and method.\n3_resources/recipes\n' | sb-review >"$tmp/out" 2>&1
[[ -f $V/3_resources/recipes/pasta.md ]] || { err "note not filed under new type:"; sed 's/^/    /' "$tmp/out" >&2; }
grep -q '^type: Recipe$' "$V/3_resources/recipes/pasta.md" 2>/dev/null || err "type: Recipe not set on the note"
[[ $(types_of | tr '\n' ' ') == "Fact Hub Recipe " ]] || err "type table is now: $(types_of | tr '\n' ' ')"
row=$(grep -F '| `Recipe`' "$V/index.md")
[[ $row == '| `Recipe`       | A dish: ingredients and method.                          |' ]] || err "row not padded like its neighbours: $row"
grep -q '^To add a type, add a row here.$' "$V/index.md" || err "prose after the table was changed"
grep -q '^Tail.$' "$V/index.md" || err "next section was changed"
SB_VAULT="$V" sb-lint "$V/3_resources/recipes/pasta.md" >"$tmp/lint" 2>&1 || { err "sb-lint rejects the filed note:"; sed 's/^/    /' "$tmp/lint" >&2; }

# 2. empty description cancels; a number still picks
mkvault
printf 's\nRecipe\n\n1\n3_resources/fact\n' | sb-review >"$tmp/out" 2>&1
[[ -f $V/3_resources/fact/pasta.md ]] || { err "cancel then '1' did not file as Fact:"; sed 's/^/    /' "$tmp/out" >&2; }
[[ $(types_of | tr '\n' ' ') == "Fact Hub " ]] || err "cancelled new type still added: $(types_of | tr '\n' ' ')"

# 3. lowercase existing name picks it (no new type); bad names and pipes are refused
mkvault
printf 's\nnot-a-type\nRecipe\nhas | pipe\nfact\n3_resources/fact\n' | sb-review >"$tmp/out" 2>&1
[[ -f $V/3_resources/fact/pasta.md ]] || { err "lowercase 'fact' did not pick Fact:"; sed 's/^/    /' "$tmp/out" >&2; }
grep -q '^type: Fact$' "$V/3_resources/fact/pasta.md" 2>/dev/null || err "type: Fact not set"
[[ $(types_of | tr '\n' ' ') == "Fact Hub " ]] || err "bad input changed the table: $(types_of | tr '\n' ' ')"

exit $rc
