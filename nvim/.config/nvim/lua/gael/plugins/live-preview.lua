return {
	"brianhuster/live-preview.nvim",
	dependencies = { "brianhuster/autosave.nvim", "ibhagwan/fzf-lua", "echasnovski/mini.pick" },
	opts = {
		cmd = "LivePreview",
		port = 8000,
		autokill = false,
		browser = "default",
		dynamic_root = false,
		sync_scroll = false,
		picker = nil,
	},
}
