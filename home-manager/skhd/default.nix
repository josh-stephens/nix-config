{ inputs, lib, config, pkgs, ... }: {
  home.packages = [ pkgs.unstable.skhd ];

  xdg.configFile."skhd" = {
    source = ./skhd;
    recursive = true;
  };
}
