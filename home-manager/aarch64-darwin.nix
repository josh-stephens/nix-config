{ inputs, darwin, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix
    ./aerospace
  ];

  home.homeDirectory = "/Users/joshsymonds";

  programs.zsh.shellAliases.update = "darwin-rebuild switch --flake \".#$(hostname -s)\"";
  programs.kitty.font.size = 13;
}
