# This file defines overlays
{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
      overlays = [
        inputs.nixneovim.overlays.default

        (self: super: {
          waybar = super.waybar.overrideAttrs (oldAttrs: {
            mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
          });
        })

        # Fix Catppuccino theme
        (self: super: {
          catppuccin-gtk = super.catppuccin-gtk.override
            {
              accents = [ "lavender" ]; # You can specify multiple accents here to output multiple themes
              size = "compact";
              tweaks = [ "rimless" "black" ]; # You can also specify multiple tweaks here
              variant = "mocha";
            };
        })
        (self: super: {
          catppuccin-gtk = super.catppuccin-plymouth.override
            {
              variant = "mocha";
            };
        })

        # Update Waybar
        (self: super: {
          waybar = super.waybar.overrideAttrs (oldAttrs: {
            version = "0.9.21";
          });
        })

        # We are setting this ourselves
        (self: super: {
          xivlauncher = super.xivlauncher.overrideAttrs (oldAttrs: {
            desktopItems = [ ];
          });
        })

        # Get gamemode working in FFXIV
        (self: super: {
          xivlauncher = super.xivlauncher.override
            {
              steam = (super.pkgs.steam.override {
                extraLibraries = pkgs: [ super.pkgs.gamemode.lib ];
              });
            };
        })

        # Override gamescope with a version that supports mouse sensitivity:
        # https://github.com/ValveSoftware/gamescope/pull/915
        # (self: super: {
        #   gamescope = super.gamescope.overrideAttrs (oldAttrs: rec {
        #     src = super.fetchFromGitHub {
        #       owner = "ValveSoftware";
        #       repo = "gamescope";
        #       rev = "4d92843a76d0792c85b408c04d8727bf2f2fdceb";
        #       sha256 = "sha256-jbx8P6Vi0N5FD581rg6Qf3rr0grnHHigW0Fcn/7pn9I=";
        #     };
        #   });
        # })
      ];
    };
  };
}
