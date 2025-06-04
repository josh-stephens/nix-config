{ inputs, darwin, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix
    ./aerospace
    ./devspaces-client
    ./ssh-hosts
    ./ssh-config
    ./claude-wrapper/darwin-idle.nix
  ];

  home.homeDirectory = "/Users/joshsymonds";
  

  programs.zsh.shellAliases.update = "sudo darwin-rebuild switch --flake \".#$(hostname -s)\"";
  programs.kitty.font.size = 13;
}
