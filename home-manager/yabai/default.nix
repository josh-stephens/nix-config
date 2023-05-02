{ inputs, lib, config, pkgs, ... }: {
  home.packages = [ pkgs.unstable.yabai ];

  xdg.configFile."yabai" = {
    source = ./yabai;
    recursive = true;
  };
}
