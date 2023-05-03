{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix

    ./yabai
    ./skhd
    ./sketchybar
  ];

  packages = [

  ];
}
