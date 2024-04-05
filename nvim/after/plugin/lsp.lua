require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = { "lua_ls", "rust_analyzer", "pyright" },
})
local capabilities = require('cmp_nvim_lsp').default_capabilities()
require("lspconfig").lua_ls.setup {
    capabilities =  capabilities
}
require("lspconfig").rust_analyzer.setup {
    capabilities =  capabilities
}
require("lspconfig").terraformls.setup{
    capabilities = capabilities
}
require("lspconfig").pyright.setup {
    capabilities = capabilities,
    on_attach = on_attach
}

vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)

