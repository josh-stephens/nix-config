{ inputs, lib, config, pkgs, ... }: {
  programs.mako = {
    enable = true;
  };

  xdg.configFile."mako" = {
    source = ./mako;
    recursive = true;
  };
}
