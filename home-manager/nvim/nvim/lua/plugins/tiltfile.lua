return {
  -- Tiltfile LSP support using Starlark LSP
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "neovim/nvim-lspconfig",
    },
    opts = function(_, opts)
      -- Register starlark-lsp with lspconfig
      local lspconfig = require("lspconfig")
      local configs = require("lspconfig.configs")
      
      -- Define the Starlark LSP configuration if not already defined
      if not configs.starlark_lsp then
        configs.starlark_lsp = {
          default_config = {
            cmd = { "starlark-lsp", "--mode=stdio" },
            filetypes = { "starlark", "bzl", "tiltfile" },
            root_dir = lspconfig.util.root_pattern("Tiltfile", "BUILD", "BUILD.bazel", "WORKSPACE", ".git"),
            settings = {},
          },
        }
      end
      
      -- Add to servers
      opts.servers = opts.servers or {}
      opts.servers.starlark_lsp = {
        -- Since we're installing via Nix, Mason shouldn't try to install it
        mason = false,
        filetypes = { "starlark", "bzl", "tiltfile" },
      }
      
      return opts
    end,
  },

  -- Enhanced Tiltfile support
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      -- Add context-aware commenting
      {
        "JoosepAlviste/nvim-ts-context-commentstring",
        opts = {
          custom_calculation = function(node, language_tree)
            if vim.bo.filetype == "tiltfile" then
              return { "# %s", "# %s" }
            end
          end,
        },
      },
    },
  },

  -- Better Python-like indentation for Tiltfiles
  {
    "Vimjas/vim-python-pep8-indent",
    ft = { "python", "tiltfile" },
  },

  -- Add Tiltfile snippets support
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    opts = function(_, opts)
      -- Add Tiltfile snippets
      local ls = require("luasnip")
      local s = ls.snippet
      local t = ls.text_node
      local i = ls.insert_node
      local f = ls.function_node

      -- Add custom Tiltfile snippets
      ls.add_snippets("tiltfile", {
        s("k8s", {
          t("k8s_yaml('"),
          i(1, "path/to/manifest.yaml"),
          t("')"),
        }),
        s("docker", {
          t("docker_build('"),
          i(1, "image-name"),
          t("', '"),
          i(2, "."),
          t("')"),
        }),
        s("local", {
          t("local_resource("),
          t({ "", "  '" }),
          i(1, "resource-name"),
          t({ "',", "  cmd='" }),
          i(2, "command"),
          t({ "',", "  deps=[" }),
          i(3, "'file.txt'"),
          t({ "]", ")" }),
        }),
        s("port", {
          t("k8s_resource('"),
          i(1, "deployment-name"),
          t("', port_forwards='"),
          i(2, "8080:80"),
          t("')"),
        }),
      })
    end,
  },

  -- Add autocompletion for Tiltfile functions
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
    },
    opts = function(_, opts)
      local cmp = require("cmp")
      
      -- Add Tiltfile-specific completion sources
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "tiltfile",
        callback = function()
          -- Add common Tiltfile functions to completion
          local tiltfile_items = {
            { label = "k8s_yaml", detail = "Apply Kubernetes YAML" },
            { label = "docker_build", detail = "Build Docker image" },
            { label = "local_resource", detail = "Define local resource" },
            { label = "k8s_resource", detail = "Configure k8s resource" },
            { label = "port_forward", detail = "Set up port forwarding" },
            { label = "watch_file", detail = "Watch file for changes" },
            { label = "fall_back_on", detail = "Fallback behavior" },
            { label = "trigger_mode", detail = "Set trigger mode" },
            { label = "env_var", detail = "Set environment variable" },
            { label = "read_file", detail = "Read file contents" },
          }
          
          -- You can enhance completion here if needed
        end,
      })
    end,
  },
}