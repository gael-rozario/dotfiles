-- convert note to template and remove leading white space
vim.keymap.set("n", "<leader>nt", ":ObsidianTemplate note<cr> :lua vim.cmd([[1,/^\\S/s/^\\n\\{1,}//]])<cr>")
vim.keymap.set("n", "<leader>nlt", ":ObsidianTemplate logtemplate<cr> :lua vim.cmd([[1,/^\\S/s/^\\n\\{1,}//]])<cr>")

-- strip date from note title and replace dashes with spaces
-- must have cursor on title
vim.keymap.set("n", "<leader>nf", ":s/\\(# \\)[^_]*_/\\1/ | s/-/ /g<cr>")

vim.keymap.set("n", "<leader>ok", ":!mv '%:p' ~/second-brain/zettelkasten<cr>:bd<cr>")
vim.keymap.set("n", "<leader>odd", ":!rm '%:p'<cr>:bd<cr>")

