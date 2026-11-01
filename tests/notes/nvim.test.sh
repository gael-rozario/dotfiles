#!/usr/bin/env bash
# Headless nvim with the real config against scratch vaults:
#  title_parity        — <leader>nn's entrypoint makes the same path+bytes as `nn`
#  daily               — today's daily note lands in 2_areas/log and passes sb-lint
#  no_plugin_frontmatter — saving a note through nvim leaves its bytes unchanged
#  mappings            — <leader>nn/nd/nf/nb exist
set -uo pipefail
DOT=${DOTFILES:-$HOME/.dotfiles}
REAL=${REAL_VAULT:-$HOME/gbrain/second-brain}
rc=0; err() { echo "  $*" >&2; rc=1; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkvault() { git clone -q "$REAL" "$1" && git -C "$1" apply "$DOT/docs/superpowers/plans/vault-templates.patch"; }
A="$tmp/vault a"; B="$tmp/vault b"; mkvault "$A"; mkvault "$B"
titles=("Go slice copy" 'a/b|c\d' $'tab\ttitle' '#hash' 'café')
printf '%s\0' "${titles[@]}" > "$tmp/titles"
# nn opens nvim at the end; stub it so nn only writes the file
mkdir -p "$tmp/stub"; printf '#!/bin/sh\nexit 0\n' > "$tmp/stub/nvim"; chmod +x "$tmp/stub/nvim"
for t in "${titles[@]}"; do SB_VAULT="$A" PATH="$tmp/stub:$PATH" nn "$t" >/dev/null 2>&1 || err "nn failed for $t"; done
runlua() { SB_VAULT="$B" NOTES_TEST_TITLES="$tmp/titles" timeout 60 nvim --headless -c "lua $1" -c 'qa!' >"$tmp/nvim.log" 2>&1; }
runlua 'local f=io.open(os.getenv("NOTES_TEST_TITLES"),"rb"); local d=f:read("a"); f:close(); for t in d:gmatch("([^%z]+)") do require("gael.notes").new_inbox_note(t) end' \
  || { err "nvim new_inbox_note failed:"; sed 's/^/    /' "$tmp/nvim.log" >&2; }
for t in "${titles[@]}"; do
  rel="0_inbox/$(printf '%s' "$t" | tr ' /|\\' '----').md"
  if [[ ! -f "$B/$rel" ]]; then err "title_parity: nvim did not create $rel"; continue; fi
  cmp -s "$A/$rel" "$B/$rel" || err "title_parity: $rel differs from nn's"
done
today=$(date +%F)
runlua 'require("gael.notes").today()' || err "daily: nvim failed"
if [[ -f "$B/2_areas/log/$today.md" ]]; then
  SB_VAULT="$B" sb-lint "$B/2_areas/log/$today.md" >"$tmp/lint" 2>&1 || { err "daily: sb-lint rejects it"; sed 's/^/    /' "$tmp/lint" >&2; }
else err "daily: 2_areas/log/$today.md not created"; fi
n="$B/0_inbox/Go-slice-copy.md"
if [[ -f $n ]]; then
  before=$(sha256sum < "$n")
  SB_VAULT="$B" timeout 60 nvim --headless "$n" -c 'normal! Go' -c 'normal! dd' -c 'w' -c 'qa!' >/dev/null 2>&1
  [[ $(sha256sum < "$n") == "$before" ]] || err "no_plugin_frontmatter: saving changed the note"
fi
# link_style: body links are root-relative markdown links (vault convention)
SB_VAULT="$B" timeout 60 nvim --headless -c 'lua local s=require("obsidian.api").format_link({label="bigO",path=require("gael.notes").vault.."/3_resources/fact/bigO.md",style=Obsidian.opts.link.style,format=Obsidian.opts.link.format}); if s~="[bigO](/3_resources/fact/bigO.md)" then io.stderr:write("got "..s.."\n") os.exit(1) end' -c 'qa!' 2>"$tmp/link" || { err "link_style:"; sed 's/^/    /' "$tmp/link" >&2; }
SB_VAULT="$B" timeout 60 nvim --headless -c 'lua for _,k in ipairs({"nn","nd","nf","nb"}) do if vim.fn.maparg("<leader>"..k,"n")=="" then io.stderr:write("missing <leader>"..k.."\n") os.exit(1) end end' -c 'qa!' 2>"$tmp/maps" || { err "mappings:"; sed 's/^/    /' "$tmp/maps" >&2; }
exit $rc
