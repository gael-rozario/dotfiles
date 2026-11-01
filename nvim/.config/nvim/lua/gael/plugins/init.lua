return {
  "nvim-lua/plenary.nvim", -- lua functions that many plugins use
  {
    "christoomey/vim-tmux-navigator", -- tmux & split window navigation
    cond = function()
      return vim.env.HERDR_PANE_ID == nil -- herdr.lua handles navigation inside herdr
    end,
  },
}
