{ inputs, lib, config, pkgs, ... }: {
  home.packages = [ pkgs.unstable.sketchybar ];

  xdg.configFile."sketchybar" = {
    source = ./sketchybar;
    recursive = true;
  };
}
