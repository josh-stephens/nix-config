{ inputs, lib, config, pkgs, ... }: {
  programs.nixneovim = {
    enable = true;
    colorscheme = "catppuccin";

    extraPlugins = [
      pkgs.vimExtraPlugins.catppuccin
    ];
  };
};
