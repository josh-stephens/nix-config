return {
  -- Treesitter configuration
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Ensure these parsers are installed
      vim.list_extend(opts.ensure_installed, {
        "lua",
        "luadoc",
        "luap",
        "python",  -- Tiltfiles are Python-based
        "starlark", -- Tiltfile uses Starlark syntax (similar to Python)
      })
    end,
  },

  -- Add Tiltfile detection
  {
    "nvim-treesitter/nvim-treesitter",
    init = function()
      -- Register Tiltfile as Python/Starlark filetype
      vim.filetype.add({
        filename = {
          ["Tiltfile"] = "tiltfile",
        },
        pattern = {
          ["Tiltfile.*"] = "tiltfile",
          [".*%.tilt"] = "tiltfile",
        },
      })
      
      -- Use Python/Starlark syntax for Tiltfiles
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "tiltfile",
        callback = function()
          vim.bo.syntax = "python"
          -- Use starlark parser if available, otherwise python
          local parsers = require("nvim-treesitter.parsers")
          if parsers.has_parser("starlark") then
            vim.treesitter.start(nil, "starlark")
          else
            vim.treesitter.start(nil, "python")
          end
        end,
      })
    end,
  },
}