-- Note capture for the second-brain vault, kept byte-identical with `nn`.
--
-- `:Obsidian new <arg>` treats its argument as an id *or path*, so a "/" in a
-- title would create a subfolder. This module builds the note itself instead:
-- the filename is nn's slug and {{title}} is the raw title, so both entry
-- points produce the same file.
local M = {}

M.vault = vim.fs.normalize(os.getenv("SB_VAULT") or "~/gbrain/second-brain")

--- nn's filename rule: each of space, / | \ becomes "-"; nothing else changes.
---@param title string
---@return string
function M.slug(title)
  return (title:gsub("[ /|\\]", "-"))
end

--- Create 0_inbox/<slug>.md from Templates/note (or reopen it if it exists).
---@param title string
---@param opts? { open?: boolean }
function M.new_inbox_note(title, opts)
  opts = opts or {}
  local slug = M.slug(title)
  if slug:gsub("-", "") == "" or slug == "index" or slug == "log" then
    return vim.notify("notes: invalid or reserved title: " .. title, vim.log.levels.ERROR)
  end
  local path = M.vault .. "/0_inbox/" .. slug .. ".md"
  if vim.uv.fs_stat(path) == nil then
    local note = require("obsidian.note").create({
      id = slug,
      title = title,
      dir = M.vault .. "/0_inbox",
      template = "note",
      verbatim = true,
      check_invalid_filename = false,
    })
    note:write()
  end
  if opts.open then
    vim.cmd.edit(vim.fn.fnameescape(path))
  end
  return path
end

--- Prompt for a title and capture it.
function M.capture()
  vim.ui.input({ prompt = "Note title: " }, function(title)
    if title and vim.trim(title) ~= "" then
      M.new_inbox_note(title, { open = true })
    end
  end)
end

--- Open (creating if needed) today's daily note in 2_areas/log.
---@param opts? { open?: boolean }
function M.today(opts)
  opts = opts or {}
  local note = require("obsidian.daily").today()
  if not note:exists() then
    note:write()
  end
  if opts.open then
    note:open()
  end
  return note
end

return M
