{ inputs, lib, config, pkgs, ... }: {
  home.packages = [ pkgs.unstable.kitty ];

  xdg.configFile."kitty" = {
    source = ./kitty;
    recursive = true;
  };
}
