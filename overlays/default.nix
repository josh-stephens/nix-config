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

        (self: super: {
          caddy = super.caddy.overrideAttrs (oldAttrs: {
            src = super.fetchFromGitHub {
              owner = "Veraticus";
              repo = "caddy";
              rev = "master"; # file.* global replacements branch @ https://github.com/caddyserver/caddy/pull/5463
              hash = "sha256-Tke/eNoeRWXOB1AxagaxPFeyV9HLm9RXjQNQRtcZI0A=";
            };
          });
        })
      ];
    };
  };
}
