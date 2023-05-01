{ inputs, lib, config, pkgs, ... }: {
  programs.nixneovim.plugins.telescope = {
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
}
