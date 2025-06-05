{ inputs, lib, config, pkgs, ... }:

{
  imports = [ inputs.linkpearl.homeManagerModules.default ];

  # Linkpearl client configuration
  # Linux servers have linkpearl configured at the system level in their host configs
  services.linkpearl = {
    enable = true;
    secretFile = "${config.xdg.configHome}/linkpearl/secret";
    join = [ "ultraviolet:9437" ];  # Connect to ultraviolet on Tailnet
    nodeId = config.networking.hostName or "cloudbank";
    verbose = false;
    pollInterval = "500ms";
    
    # Use the package from the linkpearl flake
    package = inputs.linkpearl.packages.${pkgs.system}.default;
  };
}