# This file defines overlays
{ inputs, ... }:
{
  # Single default overlay that combines everything
  default = final: prev: {
    # Import custom packages from the 'pkgs' directory
    inherit (import ../pkgs { pkgs = final; })
      myCaddy
      starlark-lsp
      nuclei;
    
    # Package modifications
    waybar = prev.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
      version = "0.9.21";
    });
    
    catppuccin-gtk = prev.catppuccin-gtk.override {
      accents = [ "lavender" ];
      size = "compact";
      tweaks = [ "rimless" "black" ];
      variant = "mocha";
    };
    
    catppuccin-plymouth = prev.catppuccin-plymouth.override {
      variant = "mocha";
    };
    
    # XIVLauncher customizations
    xivlauncher = prev.xivlauncher.override {
      steam = prev.steam.override {
        extraLibraries = pkgs: [ prev.gamemode.lib ];
      };
    } // {
      # Remove desktop items as we're setting them ourselves
      desktopItems = [];
    };
    
    # Stable packages available under pkgs.stable (if needed)
    stable = import inputs.nixpkgs-stable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
  
  # Legacy overlay references for backwards compatibility
  additions = final: _prev: import ../pkgs { pkgs = final; };
  modifications = final: prev: { };  # Empty, kept for compatibility
  unstable-packages = final: prev: { };  # Empty, no longer needed since we use unstable as primary
}