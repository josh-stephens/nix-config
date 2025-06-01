return {
  -- Mason configuration
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        -- Lua
        "lua-language-server",
        "stylua",
        
        -- Python/Starlark (for Tiltfiles)
        "pyright",
        "ruff",
        "black",
        
        -- General purpose
        "prettier",
        "shfmt",
      })
    end,
  },
}