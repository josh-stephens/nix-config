{ inputs, lib, config, pkgs, ... }: {
  home.packages = [ pkgs.unstable.wofi ];

  xdg.configFile."wofi" = {
    source = ./wofi;
    recursive = true;
  };
}
