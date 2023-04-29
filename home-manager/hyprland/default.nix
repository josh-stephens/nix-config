{ inputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.hyprland.homeManagerModules.default
  ];

  nixpkgs = {
    overlays = [
      inputs.nixpkgs-wayland.overlay
    ];
  };

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland = {
      enable = true;
      hidpi = true;
    };

    nvidiaPatches = true;
  };

  xdg.configFile."hypr" = {
    source = ./hyprland;
    recursive = true;
  };

  programs.nixneovim = {
    enable = true;
    colorscheme = "catppuccin";

    extraPlugins = [
      pkgs.vimExtraPlugins.catppuccin
    ];
  };
}
