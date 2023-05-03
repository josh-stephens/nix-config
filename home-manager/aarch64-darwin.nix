{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix

    ./yabai
    ./skhd
    ./sketchybar
  ];

  programs.zsh.shellAliases.update = "darwin-rebuild switch --flake \".#$(hostname -s)\"";
}
