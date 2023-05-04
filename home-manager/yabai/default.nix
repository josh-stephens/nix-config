{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ../../modules/services/yabai.nix
  ];
  home.packages = [ pkgs.unstable.yabai ];

  services.yabai = {
    enable = true;
    package = pkgs.unstable.yabai;
  };

  xdg.configFile."yabai" = {
    source = ./yabai;
    recursive = true;
  };
}
