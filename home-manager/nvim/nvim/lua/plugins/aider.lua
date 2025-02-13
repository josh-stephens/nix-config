return {
  "GeorgesAlkhouri/nvim-aider",
  cmd = {
    "AiderTerminalToggle", "AiderHealth",
  },
  keys = {
    { "<leader>a", "<cmd>AiderTerminalToggle<cr>", desc = "Open Aider" },
    { "<leader>as", "<cmd>AiderTerminalSend<cr>", desc = "Send to Aider", mode = { "n", "v" } },
    { "<leader>ac", "<cmd>AiderQuickSendCommand<cr>", desc = "Send Command To Aider" },
    { "<leader>ab", "<cmd>AiderQuickSendBuffer<cr>", desc = "Send Buffer To Aider" },
    { "<leader>a+", "<cmd>AiderQuickAddFile<cr>", desc = "Add File to Aider" },
    { "<leader>a-", "<cmd>AiderQuickDropFile<cr>", desc = "Drop File from Aider" },
    { "<leader>ar", "<cmd>AiderQuickReadOnlyFile<cr>", desc = "Add File as Read-Only" },
    -- Example nvim-tree.lua integration if needed
    { "<leader>a+", "<cmd>AiderTreeAddFile<cr>", desc = "Add File from Tree to Aider", ft = "NvimTree" },
    { "<leader>a-", "<cmd>AiderTreeDropFile<cr>", desc = "Drop File from Tree from Aider", ft = "NvimTree" },
  },
  dependencies = {
    "folke/snacks.nvim",
    --- The below dependencies are optional
    "catppuccin/nvim",
    "nvim-tree/nvim-tree.lua",
  },
  config = function()
    require("nvim_aider").setup({
      -- Command line arguments passed to aider
      args = {
        "--no-auto-commits",
        "--pretty",
        "--stream",
        "--no-show-model-warnings",
        "--code-theme",
        "monokai"
      },
      theme = {
        user_input_color = "#a6da95",
        tool_output_color = "#8aadf4",
        tool_error_color = "#ed8796",
        tool_warning_color = "#eed49f",
        assistant_output_color = "#c6a0f6",
        completion_menu_color = "#cad3f5",
        completion_menu_bg_color = "#24273a",
        completion_menu_current_color = "#181926",
        completion_menu_current_bg_color = "#f4dbd6",
      },
      config = {
        os = { editPreset = "nvim-remote" },
        gui = { nerdFontsVersion = "3" },
      },
      win = {
        wo = { winbar = "Aider" },
        style = "nvim_aider",
        position = "right",
        keys = {
          term_normal = {
            "<esc>",
            [[<C-\><C-n>]],
            mode = "t",
            expr = true,
            desc = "Escape only once to local mode",
          },
          hide_window = {
            "<esc>",
            function()
              require("nvim_aider.terminal").toggle()
            end,
            mode = "n",
            expr = true,
            desc = "Hide window with escape",
          },
        },
      },
      auto_insert = false,
      start_insert = false,
    })
  end,
}
