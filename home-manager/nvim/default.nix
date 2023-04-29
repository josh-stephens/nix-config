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
    colorscheme = "catppuccin";

    extraConfigVim = ''
      lua << EOF
        ${lib.strings.fileContents ./init.lua}
      EOF
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
      };
      nvim-tree = {
        enable = true;
      };
      nvim-cmp = {
        enable = true;
      };
    };

    extraPlugins = [
      pkgs.vimExtraPlugins.catppuccin
      pkgs.vimExtraPlugins.leap-nvim
      pkgs.vimExtraPlugins.nvim-web-devicons
    ];
  };
}
