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
      inputs.nixneovim.overlays.default
      inputs.neovim-nightly-overlay.overlay

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
    package = inputs.darwin-nix.packages.${system}.nix;
    useDaemon = true;

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

  # Time and internationalization
  time.timeZone = "America/Los_Angeles";

  # Users and their homes
  users.users.${user} = {
    shell = pkgs.unstable.zsh;
    home = "/Users/${user}";
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    useUserPackages = true;
    useGlobalPkgs = true;
    users = {
      # Import your home-manager configuration
      ${user} = import ../../home-manager/${system}.nix;
    };
  };

  # Security
  security.pam.enableSudoTouchIdAuth = true;

  # Services
  services.nix-daemon.enable = true;
  programs.zsh.enable = true; # This is necessary to set zsh paths properly

  # Environment
  environment = {
    pathsToLink = [ 
      "/bin"
      "/share/locale"
      "/share/terminfo"
      "/share/zsh"
    ];
  };

  system.activationScripts.applications.text = lib.mkForce ''
    echo "setting up ~/Applications..." >&2
    applications="$HOME/Applications"
    nix_apps="$applications/Nix Apps"

    # Needs to be writable by the user so that home-manager can symlink into it
    if ! test -d "$applications"; then
        mkdir -p "$applications"
        chown ${user}: "$applications"
        chmod u+w "$applications"
    fi

    # Delete the directory to remove old links
    rm -rf "$nix_apps"
    mkdir -p "$nix_apps"

    find ${config.system.build.applications}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
        while read src; do
            # Spotlight does not recognize symlinks, it will ignore directory we link to the applications folder.
            # It does understand MacOS aliases though, a unique filesystem feature. Sadly they cannot be created
            # from bash (as far as I know), so we use the oh-so-great Apple Script instead.
            /usr/bin/osascript -e "
                set fileToAlias to POSIX file \"$src\" 
                set applicationsFolder to POSIX file \"$nix_apps\"

                tell application \"Finder\"
                    make alias file to fileToAlias at applicationsFolder
                    # This renames the alias; 'mpv.app alias' -> 'mpv.app'
                    set name of result to \"$(rev <<< "$src" | cut -d'/' -f1 | rev)\"
                end tell
            " 1>/dev/null
        done
  '';

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = 4;

}
