{ inputs, lib, config, pkgs, ... }: {
  home.packages = [ pkgs.unstable.wezterm ];

  xdg.configFile."wezterm" = {
    source = ./wezterm;
    recursive = true;
  };
}
