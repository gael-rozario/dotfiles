-- obsidian.nvim (community fork) for the second-brain vault.
-- Capture goes through lua/gael/notes.lua so nvim and `nn` make identical
-- files (see that module for why `:Obsidian new` isn't used directly).
local notes = require("gael.notes")

return {
	"obsidian-nvim/obsidian.nvim",
	tag = "v3.16.10",
	lazy = false,
	config = function()
		require("obsidian").setup({
			legacy_commands = false,
			workspaces = {
				-- SB_VAULT lets tests point nvim at a scratch copy (nn/sb-* honour it too)
				{ name = "second-brain", path = notes.vault },
			},
			notes_subdir = "0_inbox",
			new_notes_location = "notes_subdir",
			note_id_func = notes.slug,
			-- Templates/note owns the frontmatter; never let the plugin add id/aliases/tags.
			frontmatter = { enabled = false },
			note = { template = "note" },
			templates = {
				folder = "Templates",
				date_format = "%Y-%m-%d",
				time_format = "%H:%M:%S",
			},
			daily_notes = {
				folder = "2_areas/log",
				date_format = "%Y-%m-%d",
				template = "logtemplate",
				default_tags = {},
				workdays_only = false,
			},
			-- render-markdown.nvim (see avante.lua) already renders checkboxes/bullets
			-- for markdown buffers; obsidian.nvim's own conceal-based UI competes with
			-- it for the same extmark ranges, which is what was eating characters.
			ui = { enable = false },
			completion = { min_chars = 2 },
			open = { func = vim.ui.open },
			-- Vault convention (index.md): body links are root-relative markdown links,
			-- e.g. [bigO](/3_resources/fact/bigO.md); wikilinks are only for hubs:.
			link = {
				format = "absolute", -- vault-relative path
				style = function(opts)
					opts.path = "/" .. opts.path
					return require("obsidian.builtin").markdown_link(opts)
				end,
			},
		})

		local map = function(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, { desc = desc })
		end
		map("<leader>nn", notes.capture, "Notes: new inbox note")
		map("<leader>nd", function() notes.today({ open = true }) end, "Notes: today's daily note")
		map("<leader>nf", "<cmd>Obsidian quick_switch<cr>", "Notes: find note")
		map("<leader>nb", "<cmd>Obsidian backlinks<cr>", "Notes: backlinks")

		-- LSP servers attaching to vault notes remap 'gd' to vim.lsp.buf.definition,
		-- which markdown servers don't support. Re-assert link-follow after attach.
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("gael_obsidian_gd", { clear = true }),
			callback = function(args)
				if vim.bo[args.buf].filetype ~= "markdown" then
					return
				end
				local path = vim.fs.normalize(vim.api.nvim_buf_get_name(args.buf))
				if not vim.startswith(path, notes.vault) then
					return
				end
				vim.schedule(function()
					vim.keymap.set("n", "gd", "<cmd>Obsidian follow_link<cr>", { buffer = args.buf, desc = "Obsidian follow link" })
				end)
			end,
		})
	end,
}
