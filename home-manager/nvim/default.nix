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

    extraConfigLua = ''
      ${lib.strings.fileContents ./init.lua}
    '';

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
      nvim-tree = {
        enable = true;
      };
      nvim-cmp = {
        enable = true;
        snippet.luasnip.enable = true;
        snippet.expand = ''
          function(args)
            require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
          end
        '';
        mapping = ''
          {
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<Tab>" = {
              modes = [ "i" "s" ];
              action = '${""}'
                function(fallback)
                  if cmp.visible() then
                    cmp.select_next_item()
                  elseif luasnip.expandable() then
                    luasnip.expand()
                  elseif luasnip.expand_or_jumpable() then
                    luasnip.expand_or_jump()
                  elseif check_backspace() then
                    fallback()
                  else
                    fallback()
                  end
                end
              '${""}';
            };
          }
        '';
      };
    };

    extraPlugins = with pkgs.vimExtraPlugins; [
      catppuccin
      leap-nvim
      nvim-web-devicons
      copilot-lua
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-rg
    ];
  };
}
