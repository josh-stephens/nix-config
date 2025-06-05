{ inputs, darwin, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix
    ./aerospace
    ./devspaces-client
    ./ssh-hosts
    ./ssh-config
    inputs.linkpearl.homeManagerModules.default
  ];

  home.homeDirectory = "/Users/joshsymonds";
  
  # Linkpearl client configuration
  services.linkpearl = {
    enable = true;
    secretFile = "${config.xdg.configHome}/linkpearl/secret";
    join = [ "ultraviolet:9437" ];  # Connect to ultraviolet on Tailnet
    nodeId = "cloudbank";
    verbose = false;
  };

  programs.zsh.shellAliases.update = "sudo darwin-rebuild switch --flake \".#$(hostname -s)\"";
  programs.kitty.font.size = 13;
}
