{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ../../modules/services/skhd.nix
  ];

  xdg.configFile."skhd" = {
    recursive = true;
  };
  
  services.skhd = {
    enable = true;
    configPath = ./skhd;
    package = pkgs.unstable.skhd;
  };
}
