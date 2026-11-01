# Notes nvim workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make keyboard-only capture and daily notes produce valid OKF notes from nvim and herdr, give filing (`sb-review`, unchanged) a keybind, and version the note scripts in dotfiles.

**Architecture:**
- The scripts move into a stow package `bin/` in `~/.dotfiles`.
- obsidian.nvim moves to the community fork, configured to match `nn` exactly.
- Vault templates get a schema patch that Gael applies.
- Two herdr popups wire up capture and filing.
- No model or agent is involved: filing stays fully manual input in `sb-review`, as it is today.

**Tech Stack:** bash, Neovim 0.11 Lua (lazy.nvim, obsidian-nvim fork, nvim-cmp), GNU stow, herdr `config.toml`.

**Spec:** `/home/gael/.dotfiles/docs/superpowers/specs/2026-11-02-notes-nvim-workflow-design.md` (sections A, B, C and E; section D "Agent hints" and "Hint privacy" were dropped by Gael on 2026-11-02).

## Global Constraints

- **Never touch the real vault.** No file writes and no git writes under `~/gbrain/second-brain`. Tests use scratch copies (`cp -a` under a temp dir). Vault changes ship as a patch that Gael applies.
- **Work on a branch in `~/.dotfiles` itself**, not a worktree, because stow symlinks resolve to `~/.dotfiles`.
  - Branch `feat/notes-nvim` from `main`.
  - `~/.dotfiles` has one pending uncommitted change from project 1 (the herdr `prefix+s` block). Gael commits it first, or Task 1 commits it on its own with the message `herdr: notes-sync on prefix+s`.
- **Note filenames:** the title, with each space, `/`, `|` and `\` replaced by `-`. No other changes and no date prefix. This must match `nn` (`tr ' /|\\' '----'`) and okf-mcp `_slug` exactly.
- **`sb-review` behaviour is unchanged.** Only its location (stow) and its new keybind change.
- **Keys:**
  - herdr `prefix+c` = capture, `prefix+i` = filing. Both are currently unbound.
  - nvim `<leader>nn` new note, `<leader>nd` daily note, `<leader>nf` find note, `<leader>nb` backlinks.
- **Commits** end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never push.

## Review Focus

1. **A title with characters `nn` leaves alone** (tabs, `#`, unicode). nvim capture must give the same filename and bytes as `nn`. → Task 3 test `title_parity`.
2. **Stow overwrites or folds `~/.local/bin`**, which also holds `no`, `nwn`, `tb-*`, pipx links and `herdr`. Everything else must be untouched, and `~/.local/bin` must stay a real directory. → Task 1 test.
3. **The capture popup gets an empty title, or is cancelled with Ctrl-C.** No file is created and the popup closes. → Task 4 test `empty_title`.
4. **The obsidian plugin rewrites frontmatter on save** (adds `id`/`aliases`/`tags`). The frontmatter must stay exactly as the template wrote it. → Task 3 test `no_plugin_frontmatter`.
5. **A vault path with a space** works in every script and in nvim. → The Task 2 and Task 3 fixtures build the scratch vault under a path containing a space.

---

### Task 1: Stow package `bin/` for the note scripts

**Files:**
- Create: `~/.dotfiles/bin/.local/bin/{nn,sb-review,sb-lint,sb-index,sb-archive,notes-sync}`. Move these with `git mv`-equivalent: copy them in, commit, then replace the originals with stow links.
- Create: `~/.dotfiles/bin/README` (one paragraph per script, plus the parity note: `sb-index` must stay byte-identical to okf-mcp's generator, `okf-mcp/tests/test_index_parity.py`). Also create `~/.dotfiles/bin/.stow-local-ignore`, containing `README`, so stow never links it.
- Create: `~/.dotfiles/tests/notes/run.sh`. A runner that executes every `tests/notes/*.test.sh` and exits non-zero on any failure. Tests live outside `bin/` so stow never links them.

**Interfaces:**
- Produces: `~/.local/bin/<script>` is a symlink into `~/.dotfiles/bin/.local/bin/<script>` for exactly the 6 scripts above.
- `~/.local/bin` stays a real directory: `stow --no-folding -d ~/.dotfiles -t ~ bin`.

- [ ] **Step 1:** Record `sha256sum` of the 6 current `~/.local/bin` scripts to a temp file.
- [ ] **Step 2:** Write `tests/notes/stow.test.sh`. It asserts:
  - each of the 6 is a symlink resolving under `~/.dotfiles/bin/`;
  - its content hash equals the recorded one;
  - `~/.local/bin` is not a symlink;
  - `no`, `nwn`, `tb-*` and `herdr` are unchanged (hash recorded the same way).
- [ ] **Step 3:** Run `bash tests/notes/run.sh`. Expected: FAIL, because the files are not symlinks.
- [ ] **Step 4:** Copy the scripts into the package, remove the originals, and run `stow --no-folding`.
- [ ] **Step 5:** Run the test. Expected: PASS. Also run `notes-sync --help 2>&1 | head -1` or `bash -n` on each script. Expected: clean.
- [ ] **Step 6:** Commit with the message `bin: version note scripts as a stow package`.

### Task 2: Vault template patch

**Files:**
- Create: `~/.dotfiles/docs/superpowers/plans/vault-templates.patch`, applicable with `git -C ~/gbrain/second-brain apply`.
  - Build it in a `git clone` of the vault inside a temp dir, then delete the clone.
  - Rewrite the `Templates/logtemplate` frontmatter to exactly the spec's YAML block (`type: DailyLog`, `description: Daily log.`, `timestamp: '{{date}}T00:00:00Z'`, `hubs:` then `- '[[log]]'`). Keep the body unchanged.
  - Apply the same schema fix to `habittemplate`, with `type: DailyLog`, the `[[habit-tracker]]` hub and `description: Habit tracker.`. Say so in the patch commit message.
- Test: `tests/notes/templates.test.sh`. It works on a scratch clone with the patch applied.

- [ ] **Step 1: Write the test.**
  - `apply --check` passes against the real vault's HEAD. This is read-only.
  - In the scratch clone, render each template with `{{title}}`=`2026-11-02` and `{{date}}`=`2026-11-02` (the same substitution `nn` does), save it as `2_areas/log/2026-11-02.md`, then run `SB_VAULT=<clone> sb-lint <file>`. Expected: exit 0.
- [ ] **Step 2:** Run it. Expected: FAIL, because the patch is missing.
- [ ] **Step 3:** Create the patch.
- [ ] **Step 4:** Run it. Expected: PASS.
- [ ] **Step 5:** Commit the patch and the test with the message `notes: vault template schema patch (for Gael to apply)`.

### Task 3: obsidian.nvim community fork + config

**Files:**
- Modify: `~/.dotfiles/nvim/.config/nvim/lua/gael/plugins/obsidian.lua` (whole file) and `nvim/.config/nvim/lazy-lock.json`.
- Test: `tests/notes/nvim.test.sh`, a headless nvim run with the real config and `SB_VAULT` pointing at a scratch vault copy.

**Interfaces:**
- **Plugin:** `obsidian-nvim/obsidian.nvim`, pinned to the latest release tag (record it in the commit message).
- **Workspace:** `{ name = "second-brain", path = os.getenv("SB_VAULT") or "~/gbrain/second-brain" }`. Drop the `vault-2` workspace.
- **Configuration.** Check option names against the pinned fork's README and docs.
  - New notes go to `0_inbox/`. The note id is the `nn` slug of the title (Global Constraints).
  - The plugin's own frontmatter management is OFF. New notes are created from template `note`, using the existing `Templates/` files that have no extension. If the fork requires `.md`, stop and report NEEDS_CONTEXT; don't duplicate templates.
  - Template substitution: `{{date}}` → `%Y-%m-%d` and `{{title}}` → the title.
  - Daily notes: folder `2_areas/log`, format `%Y-%m-%d`, template `logtemplate`.
  - `ui.enable = false`, nvim-cmp completion, and URL follow through `vim.ui.open`.
  - Keep the `gd` mapping and its `LspAttach` re-assert.
  - Add the 4 `<leader>n*` mappings from Global Constraints.

- [ ] **Step 1: Write the test.** It drives nvim with `nvim --headless -c 'lua ...' -c qa`, against a scratch vault with Task 2's patch applied.
  - `title_parity`: for the titles `Go slice copy`, `a/b|c\d`, `tab<TAB>title`, `#hash` and `café`, the note created through the plugin's new-note API has the same relative path, and the same bytes, as `nn`'s template rendering for that title. To get `nn`'s output, run it with `EDITOR=true`, or reproduce its `sed` render in the test; `nn` itself execs nvim, so pick whichever the test can drive.
  - `daily`: today's daily note is created at `2_areas/log/<today>.md`, and `sb-lint` on it gives exit 0.
  - `no_plugin_frontmatter`: a note saved through the plugin keeps its frontmatter keys exactly. No `id`, `aliases` or `tags` are added.
  - `mappings`: `vim.fn.maparg('<leader>nn','n')` is non-empty, and the same for `nd`, `nf` and `nb`, in a vault markdown buffer.
- [ ] **Step 2:** Run it. Expected: FAIL with the old plugin.
- [ ] **Step 3:** Implement, then run `:Lazy sync` headless to update the lock file.
- [ ] **Step 4:** Run it. Expected: PASS. Then run `bash tests/notes/run.sh`. Expected: all PASS.
- [ ] **Step 5:** Commit with the message `nvim: obsidian.nvim community fork, nn-identical capture, daily notes`.

### Task 4: herdr popups

**Files:**
- Modify: `~/.dotfiles/herdr/.config/herdr/config.toml`. Add two `[[keys.command]]` popup blocks in the style of the existing `prefix+s` block.
- Test: `tests/notes/herdr.test.sh`

**Interfaces:**
- **`prefix+c`, "Capture note"**:
  - command: `read -rp 'title> ' t && [ -n "$t" ] && ~/.local/bin/nn "$t"`
  - size: 80% × 70%
- **`prefix+i`, "File inbox notes"**:
  - command: `~/.local/bin/sb-review; printf '\n[press any key]'; read -rsn1 2>/dev/null || read -r _`
  - size: 90% × 85%

- [ ] **Step 1: Write the test.**
  - `herdr config check` reports ok.
  - `grep` finds exactly one block per key.
  - The keys `prefix+c` and `prefix+i` appear nowhere else in the file.
  - `empty_title`:
    - Extract the `prefix+c` command string from the TOML.
    - Run it with `bash -c` and stdin `\n` (an empty title), using a scratch `SB_VAULT` and `HOME=<temp dir>`. That temp dir's `.local/bin/nn` is a stub that records each call. The command uses the absolute path `~/.local/bin/nn`, so a `PATH` stub wouldn't intercept it.
    - Expected: no new file in `0_inbox/`, and `nn` is never invoked.
- [ ] **Step 2:** Run it. Expected: FAIL.
- [ ] **Step 3:** Add the blocks.
- [ ] **Step 4:** Run it. Expected: PASS. Do not reload herdr; Gael does that.
- [ ] **Step 5:** Commit with the message `herdr: capture (prefix+c) and inbox filing (prefix+i) popups`.

---

**Hand-off to Gael after all tasks:**
1. Apply `vault-templates.patch` and push.
2. In herdr, press `prefix+r` to reload, then try `prefix+c`, `prefix+i` and `<leader>nd`.
3. Push `feat/notes-nvim`, or merge it, as he chooses.
