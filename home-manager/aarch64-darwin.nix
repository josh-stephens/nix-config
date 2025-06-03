{ inputs, darwin, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix
    ./aerospace
    ./devspaces-client-simplified
    ./ssh-hosts
    ./ssh-config
  ];

  home.homeDirectory = "/Users/joshsymonds";
  

  programs.zsh.shellAliases.update = "sudo darwin-rebuild switch --flake \".#$(hostname -s)\"";
  programs.kitty.font.size = 13;
}
