-- insert a vault template into the current note and remove leading blank lines
-- (obsidian.nvim community fork: `:Obsidian template <name>`, legacy commands are off)
vim.keymap.set("n", "<leader>nt", ":Obsidian template note<cr> :lua vim.cmd([[1,/^\\S/s/^\\n\\{1,}//]])<cr>")
vim.keymap.set("n", "<leader>nlt", ":Obsidian template logtemplate<cr> :lua vim.cmd([[1,/^\\S/s/^\\n\\{1,}//]])<cr>")
vim.keymap.set("n", "<leader>nht", ":Obsidian template habittemplate<cr> :lua vim.cmd([[1,/^\\S/s/^\\n\\{1,}//]])<cr>")

-- (old <leader>nf "strip date prefix from title" removed: notes are no longer
-- date-prefixed; <leader>nf is now "find note", see plugins/obsidian.lua)
vim.keymap.set("n", "<leader>ok", ":!mv '%:p' ~/second-brain/zettelkasten<cr>:bd<cr>")
vim.keymap.set("n", "<leader>odd", ":!rm '%:p'<cr>:bd<cr>")
