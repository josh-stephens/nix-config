let 
  system = "aarch64-darwin";
  user = "joshsymonds";
in { inputs, lib, config, pkgs, ... }: {
  # You can import other NixOS modules here
  imports = [
    inputs.home-manager.darwinModules.home-manager
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      inputs.nixpkgs-wayland.overlay
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      (final: prev: {
        unstable = import inputs.nixpkgs-unstable {
          system = final.system;
          config.allowUnfree = true;
        };
      })

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };


  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;

      # Caches
      substituters = [
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };
  };


  networking.hostName = "cloudbank";
  networking.firewall.checkReversePath = "loose";

  # Time and internationalization
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

 # Users and their homes
  users.defaultUserShell = pkgs.zsh;

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    useUserPackages = true;
    useGlobalPackages = true;
    users = {
      # Import your home-manager configuration
      ${user} = import ../../home-manager/home.nix;
    };
  };

  # Security
  security.pam.enableSudoTouchIdAuth = true;

    # Fonts!
  fonts = {
    fonts = with pkgs; [
      (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
    ];

    fontconfig = {
      defaultFonts = {
        monospace = [ "Cartograph CF Regular" "Symbols Nerd Font Mono" ];
      };
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
