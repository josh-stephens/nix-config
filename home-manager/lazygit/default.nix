{ inputs, lib, config, pkgs, ... }: {
  programs.lazygit = {
    enable = true;
    package = pkgs.unstable.lazygit;
  };

  xdg.configFile."lazygit" = {
    source = ./lazygit;
    recursive = true;
  };
}
