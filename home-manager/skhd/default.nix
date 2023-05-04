{ inputs, lib, config, pkgs, ... }: {
  xdg.configFile."skhd" = {
    source = ./skhd;
    recursive = true;
  };
}
