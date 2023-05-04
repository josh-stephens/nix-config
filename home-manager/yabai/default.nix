{ inputs, lib, config, pkgs, ... }: {
  xdg.configFile."yabai" = {
    source = ./yabai;
    recursive = true;
  };
}
