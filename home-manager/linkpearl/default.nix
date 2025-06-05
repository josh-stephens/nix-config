{ inputs, lib, config, pkgs, ... }:

let
  # Determine if this host should run as a server or client
  isServer = config.networking.hostName == "ultraviolet";
in
{
  imports = [ inputs.linkpearl.homeManagerModules.default ];

  # Linkpearl configuration - server mode for ultraviolet, client mode for others
  services.linkpearl = {
    enable = true;
    secretFile = "${config.xdg.configHome}/linkpearl/secret";
    
    # Server mode: listen on port, no join addresses
    # Client mode: don't listen, join ultraviolet
    listen = if isServer then ":9437" else null;
    join = if isServer then [] else [ "ultraviolet:9437" ];
    
    nodeId = config.networking.hostName or "unknown";
    verbose = false;
    pollInterval = "500ms";
    
    # Use the package from the linkpearl flake
    package = inputs.linkpearl.packages.${pkgs.system}.default;
  };
}