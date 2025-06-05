{ inputs, lib, config, pkgs, ... }:

{
  imports = [ inputs.linkpearl.homeManagerModules.default ];

  # Linkpearl client configuration
  services.linkpearl = {
    enable = true;
    secretFile = "${config.xdg.configHome}/linkpearl/secret";
    join = [ "ultraviolet:9437" ];  # Connect to ultraviolet on Tailnet
    nodeId = "cloudbank";
    verbose = false;
  };
}