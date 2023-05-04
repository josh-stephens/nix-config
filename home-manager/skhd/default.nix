{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ../../modules/services/skhd.nix
  ];

  services.skhd = {
    enable = true;
    configPath = ./skhdrc;
    package = pkgs.unstable.skhd;
  };
}
