return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      -- Simple configuration
      attach_to_untracked = false,
      signs = {
        add = { text = "┃" },
        change = { text = "┃" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
    },
  },
}