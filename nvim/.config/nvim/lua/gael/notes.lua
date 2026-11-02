-- Note capture for the second-brain vault, kept byte-identical with `nn`.
--
-- The note is rendered here, exactly like nn's two seds, not via obsidian.nvim:
-- its Note.create parses the id as a path ("/" makes a subdir, ".md" is cut
-- out of the middle of titles) and its template engine prompts for unknown
-- {{vars}}. Filename = nn's slug; {{title}} = raw title, then {{date}}.
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
    local tf = assert(io.open(M.vault .. "/Templates/note", "rb"))
    local text = tf:read("a")
    tf:close()
    -- function replacements keep "%" literal; same order as nn's sed
    text = text:gsub("{{title}}", function() return title end)
    text = text:gsub("{{date}}", function() return os.date("%Y-%m-%d") end)
    vim.fn.mkdir(M.vault .. "/0_inbox", "p")
    local f = assert(io.open(path, "wb"))
    f:write(text)
    f:close()
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
