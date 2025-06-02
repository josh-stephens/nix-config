{ inputs, darwin, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix
    ./aerospace
    ./devspaces-client
    ./ssh-hosts
    ./ssh-config
    ./clipboard-sync-client
    ./clipboard-monitor
  ];

  home.homeDirectory = "/Users/joshsymonds";
  

  programs.zsh.shellAliases.update = "sudo darwin-rebuild switch --flake \".#$(hostname -s)\"";
  programs.kitty.font.size = 13;
  
  # Enable clipboard sync client for remote development
  programs.clipboard-sync-client = {
    enable = true;
  };
  
  # Enable automatic clipboard monitoring
  programs.clipboard-monitor = {
    enable = true;
  };
}
