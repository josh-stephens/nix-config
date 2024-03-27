{ inputs, lib, config, pkgs, ... }: {
  xdg.configFile."aerospace" = {
    source = ./aerospace;
    recursive = true;
  };
}
