return {
  "propet/toggle-fullscreen.nvim",
  keys = {
    {
      "<leader>z",
      function()
        require("toggle-fullscreen"):toggle_fullscreen()
      end,
      desc = "toggle-fullscreen"
    },
  },
}
