{ inputs, lib, config, pkgs, ... }: {
  home.packages = [ pkgs.unstable.wlogout ];

  xdg.configFile."wlogout" = {
    source = ./wlogout;
    recursive = true;
  };
}
