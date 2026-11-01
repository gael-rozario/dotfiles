#!/usr/bin/env bash
# vault-templates.patch applies to the real vault (read-only check) and the
# patched daily/habit templates render to notes sb-lint accepts.
set -uo pipefail
DOT=${DOTFILES:-$HOME/.dotfiles}
REAL=${REAL_VAULT:-$HOME/gbrain/second-brain}
PATCH=$DOT/docs/superpowers/plans/vault-templates.patch
rc=0; err() { echo "  $*" >&2; rc=1; }
[[ -f $PATCH ]] || { err "missing $PATCH"; exit 1; }
git -C "$REAL" apply --check "$PATCH" || err "patch does not apply to $REAL HEAD"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
V="$tmp/scratch vault"
git clone -q "$REAL" "$V" && git -C "$V" apply "$PATCH" || { err "clone/apply failed"; exit 1; }
for t in logtemplate habittemplate; do
  out="$V/2_areas/log/2026-11-02.md"
  sed -e 's|{{title}}|2026-11-02|g' -e 's|{{date}}|2026-11-02|g' "$V/Templates/$t" > "$out"
  SB_VAULT="$V" sb-lint "$out" >"$tmp/lint" 2>&1 || { err "$t renders a note sb-lint rejects:"; sed 's/^/    /' "$tmp/lint" >&2; }
  rm -f "$out"
done
exit $rc
