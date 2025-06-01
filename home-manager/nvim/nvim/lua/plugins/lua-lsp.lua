return {
  -- Enhanced Lua LSP configuration
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Override the default lua_ls settings
      opts.servers = opts.servers or {}
      opts.servers.lua_ls = {
        settings = {
          Lua = {
            runtime = {
              -- Tell the language server which version of Lua you're using
              version = "LuaJIT",
            },
            diagnostics = {
              -- Get the language server to recognize the `vim` global
              globals = { "vim", "love" },
            },
            workspace = {
              checkThirdParty = false,
              -- Make the server aware of Neovim runtime files
              library = {
                vim.env.VIMRUNTIME,
                -- Add any additional library paths here
              },
            },
            telemetry = {
              enable = false,
            },
            format = {
              enable = true,
              -- Use stylua for formatting
              defaultConfig = {
                indent_style = "space",
                indent_size = "2",
                quote_style = "double",
                call_arg_parentheses = "Always",
              },
            },
            codeLens = {
              enable = true,
            },
            completion = {
              callSnippet = "Replace",
              enable = true,
              showWord = "Disable",
            },
            hint = {
              enable = true,
              setType = false,
              paramType = true,
              paramName = "Disable",
              semicolon = "Disable",
              arrayIndex = "Disable",
            },
          },
        },
      }
      return opts
    end,
  },

  -- Ensure Lua formatting with stylua
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
      },
    },
  },

  -- Add Lua-specific debugging support
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      "jbyuki/one-small-step-for-vimkind",
      -- stylua: ignore
      keys = {
        { "<leader>daL", function() require("osv").launch({ port = 8086 }) end, desc = "Adapter Lua Server" },
        { "<leader>dal", function() require("osv").run_this() end, desc = "Adapter Lua" },
      },
      config = function()
        local dap = require("dap")
        dap.adapters.nlua = function(callback, config)
          callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
        end
        dap.configurations.lua = {
          {
            type = "nlua",
            request = "attach",
            name = "Attach to running Neovim instance",
          },
        }
      end,
    },
  },
}