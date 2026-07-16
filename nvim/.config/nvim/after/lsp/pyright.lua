return {
	filetypes = { "python" },
	before_init = function(_, config)
		local default_venv_path = vim.env.HOME .. "/venv/nvim/bin/python"
		config.settings.python.pythonPath = default_venv_path
	end,
}
