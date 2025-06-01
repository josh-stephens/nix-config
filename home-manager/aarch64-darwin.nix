{ inputs, darwin, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix
    ./aerospace
    ./devspaces-client
    ./ssh-hosts
    ./ssh-config
  ];

  home.homeDirectory = "/Users/joshsymonds";
  
  home.packages = with pkgs; [
    eternal-terminal  # ET - Low-latency SSH replacement
  ];

  programs.zsh.shellAliases.update = "sudo darwin-rebuild switch --flake \".#$(hostname -s)\"";
  programs.kitty.font.size = 13;
}
