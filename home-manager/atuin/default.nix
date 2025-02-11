{ inputs, lib, config, pkgs, ... }: {
  programs.atuin = {
    enable = true;
    package = pkgs.unstable.atuin;

    enableZshIntegration = true;
  };
}