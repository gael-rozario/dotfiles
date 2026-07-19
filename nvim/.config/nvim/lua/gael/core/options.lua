-- vim.cmd("let g:netrw_liststyle = 3")

local opt = vim.opt

opt.guicursor = ""
opt.relativenumber = true
opt.number = true

-- tabs and indentation
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true

opt.wrap = false

-- search settings
opt.ignorecase = true
opt.smartcase = true

opt.swapfile = false
opt.backup = false
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
opt.undofile = true

opt.hlsearch = true
opt.incsearch = true

opt.termguicolors = true

opt.scrolloff = 8
opt.signcolumn = "yes"
opt.isfname:append("@-@")

opt.updatetime = 50
opt.conceallevel = 1

-- render-markdown.nvim needs conceallevel = 2 to render its bullet/checkbox
-- icon overlays; at 1 the concealed markers just vanish with no icon shown.
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	group = vim.api.nvim_create_augroup("gael_markdown_conceal", { clear = true }),
	callback = function()
		vim.opt_local.conceallevel = 2
		vim.opt_local.concealcursor = "nc"
	end,
})
