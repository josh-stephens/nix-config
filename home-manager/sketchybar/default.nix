{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ../../modules/services/sketchybar.nix
  ];

  services.sketchybar = {
    enable = true;
    package = pkgs.unstable.sketchybar;
  };

  xdg.configFile."sketchybar" = {
    source = ./sketchybar;
    recursive = true;
  };
}
