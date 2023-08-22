{ inputs, lib, config, pkgs, ... }: {
  programs.eww = {
    enable = true;
    package = pkgs.eww-exclusiver;
    configDir = ./eww;
  };
}
