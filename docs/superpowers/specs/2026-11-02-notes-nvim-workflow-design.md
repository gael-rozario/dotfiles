# Notes nvim workflow — design

> **Revision 2026-11-02 (Gael):** no model involvement. Section **D (agent hints)**, the "Settled after the builder check" items about the hint command contract, the order of hint prompts and hint resolution, and the **Hint privacy** section are **dropped**. Filing stays fully manual input in `sb-review`, unchanged. Only its keybind (herdr `prefix+i`) is new. Goal 3 now means opening `sb-review` in a popup, with no pre-fill. The anti-goals about hints no longer apply.


Project 2 of the notes-system rework (spec:
`~/.claude/plans/i-am-senior-devops-cached-emerson.md`). Project 1 (reliable
sync: okf-mcp transactional writes, `notes-sync` on herdr `prefix+s`) is
merged and live.

## Intent

Gael lives in nvim and herdr panes, and agents work in git worktrees around him.
Capturing a thought and filing it later must be **fast and keyboard-only**.
Everything created must be valid OKF from the first keystroke, so that
nothing needs fixing up at filing time and agents can trust the vault.

Today's gaps:
- obsidian.nvim (the unmaintained `epwalsh` repo) writes new notes to the vault
  root with a `YYYY-MM-DD_` prefix and no frontmatter.
- Daily notes aren't wired up.
- Links try macOS `open`.
- The daily template uses the retired `date:`/`tags:` schema.
- Filing means running `sb-review` by hand and answering every prompt from scratch.

## Goals

1. **Capture**, from nvim or from any herdr pane, lands one valid inbox note:
   - `0_inbox/<Title-With-Dashes>.md` (exactly `nn`'s naming);
   - frontmatter from `Templates/note`;
   - `type` may be empty.
2. **Daily note**, from one command, opens or creates `2_areas/log/YYYY-MM-DD.md` as a valid `DailyLog`.
3. **Filing**, from a herdr keybind usable any time, opens `sb-review` in a popup.
   - Each prompt (type, folder, empty description, empty hubs) is pre-filled with an agent's suggestion.
   - Enter accepts; every existing key still overrides.
4. **No behaviour drift** between nvim capture, `nn`, okf-mcp `create_note` and `sb-lint`. Same names, same frontmatter keys.
5. **The local scripts are versioned:** `nn`, `sb-*` and `notes-sync` live in `~/.dotfiles` (stow), not only in `~/.local/bin`.

## Non-goals

- No new note types, folders or taxonomy changes.
- No change to okf-mcp (its `suggest_folders` already serves agents).
- No background automation. Capture, filing and sync are all explicit keybinds
  (Gael's standing preference). Hints run only when filing starts.
- Mermaid/markmap rendering, attachments and Excalidraw migration belong to project 3.
- third-brain.

## Anti-goals (failure even if it "works")

- **Filing ever blocks or fails because the hint agent is slow, down, wrong or disabled.**
  `sb-review` must behave exactly as today when hints are missing.
- A hint is applied without Gael seeing it (no silent auto-filing).
- nvim capture creates a file `sb-lint` errors on, or a name that differs from `nn`'s.
- Note content is sent anywhere other than the configured hint command.

## Decided

**By Gael:**
- Keep obsidian.nvim.
- Use the community fork `obsidian-nvim/obsidian.nvim`.
- Filing has its own keybind, usable any time, and is **not** called an "end-of-day" pass.
- Use `sb-review` + agent hints; Enter accepts a hint.
- The hint command is configurable to stay agent-agnostic: `SB_HINT_CMD`, default `claude -p --output-format json`.
- Hints are cached by note content hash.

**By Claude (Gael to check):**
- **Daily notes go straight to `2_areas/log/`, not the inbox.** Their destination is fixed by convention, so inbox triage adds nothing.
- **The daily note frontmatter** is `type: DailyLog`, a stub `description: Daily log.`, the `timestamp`, and `hubs: ['[[log]]']`. Gael edits the description later; lint only requires that it is non-empty.
- **Keybinds:**
  - herdr `prefix+c`: capture (popup prompts for a title, then `nn "<title>"` opens nvim in the popup).
  - herdr `prefix+i`: inbox filing (`sb-review` in a large popup).
  - Both keys are currently unbound.
  - nvim `<leader>nn`: new inbox note.
  - nvim `<leader>nd`: today's daily note.
  - nvim `<leader>nf`: find note (obsidian quick-switch).
  - nvim `<leader>nb`: backlinks.
- **Hints cover** type, folder, and description/hubs **only when those are empty**. A hint never overwrites what Gael wrote.
- **Hubs:** hints may only propose existing hubs from `3_resources/hubs/`. Hints never create hubs; Gael can still type a new one.

## How it works

### A. obsidian.nvim (dotfiles `nvim/.config/nvim/lua/gael/plugins/obsidian.lua`)

- **Plugin and workspaces:**
  - Switch to `obsidian-nvim/obsidian.nvim` (pin a release tag and update `lazy-lock.json`).
  - Keep the `vault-1` (second-brain) workspace. Drop `vault-2`/third-brain from the workspace list, since it's out of scope. (Builder: keep it if removing it breaks something.)
- **Behaviour to configure.** Exact option names must be checked against the fork's current README, because the fork renamed several options (e.g. `disable_frontmatter` → `frontmatter.enabled`, `legacy_commands`).
  - New notes go to `0_inbox/`, with id = title with spaces, `/`, `|` and `\` replaced by `-`. Nothing else changes and there is no date prefix. This is identical to `nn` and okf-mcp `_slug`.
  - New notes get `Templates/note` applied, with `{{title}}` and `{{date}}` substituted (`%Y-%m-%d`). obsidian.nvim's own frontmatter management stays **off**: the template owns frontmatter, and the plugin must not rewrite it (e.g. add `id`/`aliases`/`tags`).
  - Daily notes: folder `2_areas/log`, `%Y-%m-%d`, template `Templates/logtemplate`.
  - Templates folder `Templates`.
    - The vault's template files have **no `.md` extension** (`note`, `logtemplate`, `habittemplate`), and `nn` depends on `Templates/note`.
    - If the fork requires `.md`, add `.md` copies and point `nn` at the same file. There must be one source of truth. Do not fork template content.
  - Following URLs uses `vim.ui.open` (Linux).
  - Keep `ui.enable = false`. render-markdown.nvim owns rendering; see the existing comment.
  - Keep nvim-cmp completion and the existing `gd` link-follow mapping plus its `LspAttach` re-assert.
  - Add the `<leader>n*` mappings above, scoped to markdown buffers in the vault where the plugin allows it.

### B. Vault template fix (Gael applies a patch; never edited directly)

Rewrite `Templates/logtemplate` frontmatter to the current schema. Keep the body (checklists) unchanged:
```yaml
---
type: DailyLog
description: Daily log.
timestamp: '{{date}}T00:00:00Z'
hubs:
- '[[log]]'
---
```
- Check `habittemplate` too. It has the same old schema; fix it or leave it, but say which in the patch notes.
- Verify by creating today's daily note in a scratch copy of the vault, then run `sb-lint` on it: no ERRORs.

### C. herdr popups (dotfiles `herdr/.config/herdr/config.toml`)

- Follow the style of the existing popup blocks (`prefix+s` notes-sync, `prefix+t` timew).
- Call scripts by absolute `~/.local/bin/...` path.
- Capture popup:
  - It reads a title. An empty title cancels.
  - It then runs `~/.local/bin/nn "$title"`, so nvim opens in the popup and closing it closes the popup.
- Filing popup:
  - It runs `~/.local/bin/sb-review`, followed by the "press any key" wait.
  - Size it about 90%×85%, since previews are long.

### D. Agent hints (`sb-review` + a new `sb-hints`)

**`sb-hints` (new bash script, `~/.local/bin`)**
- **Input:** the inbox notes (all `0_inbox/*.md` except `index.md`).
- **Cache:** `~/.cache/sb-hints/<sha256 of file content>.json`. Notes already cached are skipped. Only notes with no cached entry go into a **single batch call**.
- **Prompt contents:**
  - the live type table (type + description) parsed from `index.md`, the same way `load_types` does in `sb-review`;
  - the existing hub names;
  - per note: path, current frontmatter, the body truncated to about 4 KB, and that note's top-5 `suggest_dirs` candidates (reuse sb-review's function: move it into a small sourced lib, or call `sb-review --suggest-dirs`; builder's choice, keep one implementation).
- **Output:** strict JSON, an array of `{path, type, folder, description, hubs}`.
  - Validate each field and drop invalid ones, keeping the valid ones:
    - `type` must be in the table;
    - `folder` must match `^(1_projects|2_areas|3_resources)(/[^/.][^/]*)*$` and must not be `3_resources/hubs` unless the type is `Hub`;
    - `hubs` must be a subset of the existing hubs.
  - Write one cache file per note.
  - With `claude -p --output-format json`, the model text is in `.result`. Extract the JSON array from it. Tolerate fenced code.
- **Failure handling:**
  - A non-zero exit, a timeout (default 90 s, `SB_HINT_TIMEOUT`) or unparsable output writes nothing and exits 0. It logs one line to stderr and to `~/.cache/sb-hints/last-error`.
  - `SB_HINT_CMD=false` (or empty) disables hints.

**`sb-review` changes**
- **At start:** launch `sb-hints` in the background, then begin the first note immediately.
- **Per note:** look up the cache by content hash, waiting **at most 3 s** for it on the first note only. Then show it in the preview as one line, e.g. `hint: CodeSnippet → 3_resources/code-snip  hubs: go  "…description…"`, or `hint: (none)`.
- **Prompts:**
  - `pick_type`: when the type is empty or unknown, the hinted type is the default (Enter takes it) and the numbered menu is unchanged.
  - `pick_dest`: the hinted folder becomes option 1 (marked `← hint`), with the existing ranked suggestions below it (deduplicated).
  - Empty `description`: prompt `description [<hint>] >`. Enter accepts the hint and anything typed replaces it. With no hint, keep today's behaviour (lint will complain as now).
  - Empty `hubs`: prompt `hubs [<hint list>] (Enter=accept, -=none) >`.
- **Unchanged:** existing keys (`s t d k e q`), lint gate, filing, hub stub creation, indexing and archive behaviour.
- **If a note was edited** (`[e]dit`) after its hint was computed, the content hash changes. The hint is then treated as missing for that note. Do not re-run it synchronously.

### E. Dotfiles: version the scripts

- Add a stow package `bin/` → `~/.local/bin/`, containing `nn`, `sb-review`, `sb-lint`, `sb-index`, `sb-archive`, `sb-hints` and `notes-sync`. Move the current files in, then `stow bin`.
- Verify byte-identical before and after. `notes-sync` and `sb-index` parity were just reviewed; don't change them here.
- Add `bin/README` (one paragraph: what each script is, and that `sb-index` must stay byte-identical with okf-mcp's generator; see `okf-mcp/tests/test_index_parity.py`).

## Testing expectations

- **nvim:** a headless test (`nvim --headless` with the real config pointed at a scratch vault copy) that:
  - creates a note through the plugin's API/command and asserts its path and frontmatter, byte-for-byte equal to what `nn` produces for the same title (strip the nvim invocation from `nn`, or compare template output);
  - creates today's daily note and runs `sb-lint` on both: no ERROR.
- **sb-hints:**
  - a fake `SB_HINT_CMD` that echoes canned JSON, covering valid, partly-invalid, fenced and garbage output, plus a timeout;
  - cache-hit test: second run makes no call;
  - disabled test.
- **sb-review:**
  - piped-input run on a scratch vault with a pre-seeded cache: Enter-only filing applies the hinted type and folder, and the description and hubs prompts accept hints;
  - with no cache, behaviour and output are identical to today's (diff the transcript against current `sb-review` on the same input).
- **Safety:** nothing ever runs against `~/gbrain/second-brain`. Scratch copies only, and Gael applies any vault patch.

## Settled after the builder check (Claude's calls)

- **Hint command contract.** The prompt goes to `SB_HINT_CMD` on **stdin**, and the answer comes back on stdout.
  - Test fakes and other agents follow the same contract.
  - The default runs isolated: from a fresh temp dir as the working directory, with no tools, no MCP servers and no session persistence. Use whatever `claude --help` offers for each of these, e.g. empty allowed tools, strict empty MCP config, no persistence.
  - Isolation keeps note content inside the hint call, stops the model acting on the vault, and avoids slow MCP connects.
  - If a flag doesn't exist, use a wrapper. Don't drop the isolation.
- **New prompts appear only when a hint exists** for that empty field. With no cache, the `sb-review` transcript must be identical to today's.
  - Order per note: type → hubs → description → folder. Hubs come before folder because hubs feed `suggest_dirs`.
  - Accepted hubs are written in the list form `hubs:\n- '[[x]]'`, replacing `hubs: []`.
- **Hints are resolved once per note**, at its first preview, and kept in memory for the whole review of that note.
  - Changing the type with `t` or accepting a hint does not drop the remaining hints. Only `[e]dit` drops them, because the content is then genuinely different.
  - After `t`, a hinted type that no longer matches is just ignored. Folder and hub hints still show.
- **Stow scope.** The `bin/` package contains exactly the 7 scripts listed.
  - Use `stow --no-folding`, so `~/.local/bin` stays a real directory.
  - `no`, `nwn`, `tb-*` (third-brain), pipx links and `herdr` are untouched.
- **Test vault override.** `obsidian.lua`'s workspace path honours `SB_VAULT`, as `nn` and `sb-*` already do. The headless test points it at a scratch copy.

## Left to the builder

- Exact fork option names and version pin.
- Whether to share `suggest_dirs` via a sourced lib or a flag.
- The popup sizes.
- The hint prompt wording.
- The `jq` vs `python3` choice for JSON in bash (both are present).

## Hint privacy (decided by Gael: opt-out flag)

- **Never sent:** a note whose frontmatter has `private: true`, or whose `hubs` include `[[private]]`, never goes to the hint command.
  - It is filtered out in `sb-hints` before the batch is built, and `sb-review` shows it as `hint: (none, private)`.
  - Everything else gets hints.
- **Lint:** `private` must not trip `sb-lint`, which is fine because unknown keys are ignored today. Keep it that way.
  - If the `[[private]]` hub is used and doesn't exist yet, `sb-review`'s normal hub-stub creation handles it at filing time.
- **Tests:**
  - A private note (either form) is never present in the stdin captured by the fake `SB_HINT_CMD`.
  - No cache file is written for it.
