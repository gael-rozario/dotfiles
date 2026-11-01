  return {
    "mistweaverco/kulala.nvim",
    keys = {
      { "<leader>ps", desc = "Send request" },
      { "<leader>pa", desc = "Send all requests" },
      { "<leader>pb", desc = "Open scratchpad" },
    },
    ft = {"http", "rest"},
    opts = {
      global_keymaps = false,
      global_keymaps_prefix = "<leader>pc",
      kulala_keymaps_prefix = "",
    },
  }
