return {
  -- Tiltfile and other syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "markdown",
        "markdown_inline", 
        "json",
        "jsonc",
        "python",  -- For Tiltfiles
      },
    },
  },
  
  -- Simple Tiltfile detection
  {
    "neovim/nvim-lspconfig",
    init = function()
      -- Set up Tiltfile to use Python syntax highlighting
      vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
        pattern = {"Tiltfile", "*.tilt", "Tiltfile.*"},
        callback = function()
          vim.bo.filetype = "python"
          vim.bo.commentstring = "# %s"
        end,
      })
    end,
  },
}