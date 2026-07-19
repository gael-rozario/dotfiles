return {
	"epwalsh/obsidian.nvim",
	version = "*", -- recommended, use latest release instead of latest commit
	lazy = false,
	ft = "markdown",
	dependencies = {
		-- Required.
		"nvim-lua/plenary.nvim",

		-- see below for full list of optional dependencies 👇
	},
	config = function()
		require("obsidian").setup({
			workspaces = {
				{
					name = "vault-1",
					path = "~/gbrain/second-brain",
					-- overrides = {
					-- 	notes_subdir = "inbox",
					-- },
				},
				{
					name = "vault-2",
					path = "~/gbrain/third-brain",
					-- overrides = {
					-- 	notes_subdir = "inbox",
					-- },
				},
			},
			mappings = {
				-- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
				["gd"] = {
					action = function()
						return require("obsidian").util.gf_passthrough()
					end,
					opts = { noremap = false, expr = true, buffer = true },
				},
			},
			new_notes_location = "notes_subdir",
			disable_frontmatter = true,
			-- render-markdown.nvim (see avante.lua) already renders checkboxes/bullets
			-- for markdown buffers; obsidian.nvim's own conceal-based UI competes with
			-- it for the same extmark ranges, which is what was eating characters.
			ui = { enable = false },
			templates = {
				subdir = "Templates",
				date_format = "%Y-%m-%d",
				time_format = "%H:%M:%S",
			},
			completion = {
				nvim_cmp = true,
				min_chars = 2,
			},
			follow_url_func = function(url)
				-- Open the URL in the default web browser.
				vim.fn.jobstart({ "open", url }) -- Mac OS
				-- vim.fn.jobstart({"xdg-open", url})  -- linux
				-- vim.cmd(':silent exec "!start ' .. url .. '"') -- Windows
				-- vim.ui.open(url) -- need Neovim 0.10.0+
			end,
			wiki_link_func = "use_alias_only",
			-- note_id_func = "{{date}}_{{title}}",
			note_id_func = function(title)
				-- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
				-- In this case a note with the title 'My new note' will be given an ID that looks
				-- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
				local suffix = ""
				if title ~= nil then
					-- If title is given, transform it into valid file name.
					suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
				else
					-- If title is nil, just add 4 random uppercase letters to the suffix.
					for _ = 1, 4 do
						suffix = suffix .. string.char(math.random(65, 90))
					end
				end
				return tostring(os.date("%Y-%m-%d")) .. "_" .. suffix
			end,
		})

		-- LSP servers attaching to vault notes remap 'gd' to vim.lsp.buf.definition,
		-- which markdown servers don't support. Re-assert the Obsidian mapping after attach.
		local vault_root = vim.fs.normalize("~/gbrain")
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("gael_obsidian_gd", { clear = true }),
			callback = function(args)
				if vim.bo[args.buf].filetype ~= "markdown" then
					return
				end
				local path = vim.fs.normalize(vim.api.nvim_buf_get_name(args.buf))
				if not vim.startswith(path, vault_root) then
					return
				end
				vim.schedule(function()
					vim.keymap.set("n", "gd", function()
						return require("obsidian").util.gf_passthrough()
					end, { noremap = false, expr = true, buffer = args.buf, desc = "Obsidian follow link" })
				end)
			end,
		})
	end,
}
