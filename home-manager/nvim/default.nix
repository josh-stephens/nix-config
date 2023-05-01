{ inputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.nixneovim.nixosModules.default
  ];

  nixpkgs = {
    overlays = [
      inputs.nixneovim.overlays.default
    ];
  };

  programs.nixneovim = {
    enable = true;
    colorscheme = "catppuccin-mocha";

    plugins = {
      lsp = {
        enable = true;
        servers = {
          bashls.enable = true;
          html.enable = true;
          jsonls.enable = true;
          rnix-lsp.enable = true;
          gopls.enable = true;
          rust-analyzer.enable = true;
        };
      };
      lspkind = {
        enable = true;
        extraLua.post = ''
          local lspkind = require("lspkind")
          lspkind.init({
            symbol_map = {
              Copilot = "",
            },
          })

          vim.api.nvim_set_hl(0, "CmpItemKindCopilot", {fg ="#6CC644"})
        '';
      };
      treesitter = {
        enable = true;
        indent = true;
      };
      mini = {
        enable = true;
        ai.enable = true;
        jump.enable = true;
      };
      gitsigns = {
        enable = true;
      };
      lualine = {
        enable = true;
        theme = "catppuccin";
        extensions = [ "fzf" "nvim-tree" ];
      };
      luasnip = {
        enable = true;
      };
      nvim-tree = {
        enable = true;
      };
      nvim-cmp = {
        snippet.luasnip.enable = true;
        enable = true;
        mappingPresets = [ "insert" ];
        mapping = {
          "<Tab>" = ''
            cmp.mapping(function(fallback)
              local has_words_before = function()
                unpack = unpack or table.unpack
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
              end
              local luasnip = require("luasnip")

              if cmp.visible() then
                cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
              -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable() 
              -- they way you will only jump inside the snippet region
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              elseif has_words_before() then
                cmp.complete()
              else
                fallback()
              end
            end, { "i", "s" })
          '';
          "<S-Tab>" =''
            cmp.mapping(function(fallback)
              local has_words_before = function()
                unpack = unpack or table.unpack
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
              end
              local luasnip = require("luasnip")

              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { "i", "s" })
          '';
          "<C-b>" = "cmp.mapping.scroll_docs(-4)";
          "<C-f>" = "cmp.mapping.scroll_docs(4)";
          "<C-Space>" = "cmp.mapping.complete()";
          "<C-c>" = "cmp.mapping.abort()";
          "<CR>" = "cmp.mapping.confirm({ select = false, behavior = cmp.ConfirmBehavior.Replace })";
        };
        sources = {
          "copilot" = {
            enable = true;
            groupIndex = 2;
          };
          "nvim_lsp" = {
            enable = true;
            groupIndex = 2;
            entryFilter = ''
              function(entry, ctx)
                return require('cmp.types').lsp.CompletionItemKind[entry:get_kind()] ~= 'Text'
              end
            '';
          };
          "buffer" = {
            enable = true;
            groupIndex = 2;
            option = {
              keyword_length = 5;
            };
          };
          "luasnip" = {
            enable = true;
            groupIndex = 2;
            option = {
              "use_show_condition" = false;
              show_autosnippets = true;
            };
          };
          "path" = {
            enable = true;
            groupIndex = 2;
          };
          "rg" = {
            enable = true;
            groupIndex = 2;
            option = {
              keyword_length = 5;
            };
          };
        };
        sorting = {
          priority_weight = 2;
          comparators = ''{
            require("copilot_cmp.comparators").prioritize,
            -- Below is the default comparitor list and order for nvim-cmp
            cmp.config.compare.offset,
            -- cmp.config.compare.scopes, --this is commented in nvim-cmp too
            cmp.config.compare.exact,
            cmp.config.compare.score,
            cmp.config.compare.recently_used,
            cmp.config.compare.locality,
            cmp.config.compare.kind,
            cmp.config.compare.sort_text,
            cmp.config.compare.length,
            cmp.config.compare.order,
          }'';
        };
      };
      telescope = {
        enable = true;
        extraConfig = {
          layout_strategy = "flex";
          layout_config = { anchor = "N"; };
          scroll_strategy = "cycle";
          theme = "require('telescope.themes').get_dropdown { layout_config = { prompt_position = 'top' } }";
        };
        extraLua.post = ''
          local telescopeBorderless = function(flavor) 
            local cp = require("catppuccin.palettes").get_palette(flavor)

            return {
              TelescopeBorder = { fg = cp.surface0, bg = cp.surface0 },
              TelescopeSelectionCaret = { fg = cp.flamingo, bg = cp.surface1 },
              TelescopeMatching = { fg = cp.peach },
              TelescopeNormal = { bg = cp.surface0 },
              TelescopeSelection = { fg = cp.text, bg = cp.surface1 },
              TelescopeMultiSelection = { fg = cp.text, bg = cp.surface2 },

              TelescopeTitle = { fg = cp.crust, bg = cp.green },
              TelescopePreviewTitle = { fg = cp.crust, bg = cp.red },
              TelescopePromptTitle = { fg = cp.crust, bg = cp.mauve },

              TelescopePromptNormal = { fg = cp.flamingo, bg = cp.crust },
              TelescopePromptBorder = { fg = cp.crust, bg = cp.crust },
            }
          end

          require("catppuccin").setup {
            highlight_overrides = {
              latte = telescopeBorderless('latte'),
              frappe = telescopeBorderless('frappe'),
              macchiato = telescopeBorderless('macchiato'),
              mocha = telescopeBorderless('mocha'),
            },
          }

        '';
      };
    };

    extraPlugins = with pkgs.vimExtraPlugins; [
      catppuccin
      leap-nvim
      nvim-web-devicons
      copilot-lua
      copilot-cmp
      cmp-nvim-lsp
      cmp-luasnip
      cmp-buffer
      cmp-path
      cmp-rg
      Comment-nvim
    ];

    extraConfigLua = ''
      ${lib.strings.fileContents ./init.lua}

      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local servers = { 'bashls', 'html', 'jsonls', 'rnix', 'gopls', 'rust_analyzer' }
      for _, lsp in ipairs(servers) do
        lspconfig[lsp].setup {
          -- on_attach = my_custom_on_attach,
          capabilities = capabilities,
        }
      end

      require("copilot").setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
      })

      require("copilot_cmp").setup({
        formatters = {
          insert_text = require("copilot_cmp.format").remove_existing
        },
      })
    '';
  };
}
