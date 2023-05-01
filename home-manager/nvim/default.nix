{ inputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.nixneovim.nixosModules.default

    ./lsp.nix
    ./nvim-cmp.nix
    ./telescope.nix
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
