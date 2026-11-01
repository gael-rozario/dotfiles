return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			javascript = { "eslint_d" },
			typescript = { "eslint_d" },
			javascriptreact = { "eslint_d" },
			typescriptreact = { "eslint_d" },
			svelte = { "eslint_d" },
			python = { "pylint" },
			["yaml.github"] = { "actionlint" },
			terraform = { "terraform_validate" },
			hcl = { "terraform_validate" },
		}

		vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
			pattern = { "*.yml", "*.yaml" },
			callback = function()
				if vim.fn.expand("%:p"):match("%.github/workflows/") then
					vim.bo.filetype = "yaml.github"
				end
			end,
		})

		-- Use pylint from the nvim venv when present, so it shares pyright's Python env
		local venv_pylint = vim.env.HOME .. "/venv/nvim/bin/pylint"
		if vim.fn.executable(venv_pylint) == 1 then
			lint.linters.pylint.cmd = venv_pylint
		end

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				lint.try_lint()
			end,
		})

		vim.keymap.set("n", "<leader>l", function()
			lint.try_lint()
		end, { desc = "Trigger linting for current file" })
	end,
}

