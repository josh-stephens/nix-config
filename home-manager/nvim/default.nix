{ inputs, lib, config, pkgs, ... }: {
  home.packages = with pkgs.unstable; [
    nodejs_20
    ripgrep
    fd
    rustc
    cargo
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  xdg.configFile = {
    "nvim/init.lua".source = ./config/init.lua;
    "nvim/lua/plugins".source = ./config/lua/plugins;
    "nvim/lua/core".source = ./config/lua/core;
  };
}
