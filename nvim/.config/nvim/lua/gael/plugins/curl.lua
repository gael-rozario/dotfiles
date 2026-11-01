return {
	"oysandvik94/curl.nvim",
	config = function()
		require("curl").setup()
		vim.filetype.add({
			extension = {
				curl = "curl",
			},
		})
	end,
}
