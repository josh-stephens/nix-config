let
  system = "x86_64-linux";
  user = "joshsymonds";
in
{ inputs, outputs, lib, config, pkgs, ... }: {
  # You can import other NixOS modules here
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.agenix.nixosModules.default
    # inputs.agenix-rekey.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
    inputs.xremap-flake.nixosModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
  ];

  # Hardware setup
  hardware = {
    cpu = {
      intel.updateMicrocode = true;
    };
    opengl = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
      ];
      driSupport = true;
      driSupport32Bit = true;
    };
    enableAllFirmware = true;
  };

  nixpkgs = {
    # You can add overlays here
    overlays = [
      inputs.nixneovim.overlays.default
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      packageOverrides = pkgs: {
        vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
      };
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
        "https://hyprland.cachix.org"
        "https://cache.nixos.org"
        "https://nixpkgs-wayland.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      ];
    };
  };

  networking = {
    hostName = "ultraviolet";
    firewall = {
      enable = true;
      checkReversePath = "loose";
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ 51820 config.services.tailscale.port ];
      allowedTCPPorts = [ 22 80 443 ];
    };
    defaultGateway = "192.168.1.1";
    nameservers = [ "192.168.1.1" ];
    interfaces.eth0.ipv4.addresses = [{
      address = "192.168.1.200";
      prefixLength = 24;
    }];
  };

  boot = {
    kernelModules = [ "coretemp" "kvm-intel" ];
    supportedFilesystems = [ "ntfs" ];
    kernelParams = [ ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot/efi";
    };
  };

  # Time and internationalization
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # Default programs everyone wants
  virtualisation.docker.enable = true;

  # Users and their homes
  users.defaultUserShell = pkgs.zsh;
  users.users.${user} = {
    shell = pkgs.unstable.zsh;
    home = "/home/${user}";
    initialPassword = "correcthorsebatterystaple";
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAQ4hwNjF4SMCeYcqm3tzUxZWadcv7ZLJbCa/mLHzsvw josh+cloudbank@joshsymonds.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINTWmaNJwRqzDMdfVOXbX6FNjcJ94VRK+aKLI2NqrcWV josh+morningstar@joshsymonds.com"
    ];
    extraGroups = [ "wheel" config.users.groups.keys.name "docker" ];
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    useUserPackages = true;
    useGlobalPkgs = true;
    users = {
      # Import your home-manager configuration
      ${user} = import ../../home-manager/headless-${system}.nix;
    };
  };

  # Security
  security = {
    rtkit.enable = true;
    sudo.extraRules = [
      {
        users = [ "${user}" ];
        commands = [
          {
            command = "ALL";
            options = [ "SETENV" "NOPASSWD" ];
          }
        ];
      }
    ];
  };

  # Services
  services.thermald.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
  programs.ssh.startAgent = true;

  services.xremap = {
    serviceMode = "user";
    userName = "${user}";
    config = {
      modmap = [
        {
          name = "Global";
          remap = {
            CapsLock = "Esc";
          };
        }
      ];
    };
  };

  services.tailscale = {
    enable = true;
    package = pkgs.unstable.tailscale;
  };

  services.mullvad-vpn = {
    enable = true;
    package = pkgs.unstable.mullvad-vpn;
  };

  programs.zsh.enable = true;

  services.jellyfin = {
    enable = true;
    package = pkgs.unstable.jellyfin;
    openFirewall = true;
  };

  services.sonarr = {
    enable = true;
    openFirewall = true;
    package = pkgs.unstable.sonarr;
  };

  services.radarr = {
    enable = true;
    openFirewall = true;
    package = pkgs.unstable.radarr;
  };

  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  services.deluge = {
    enable = true;
    openFirewall = true;
    package = pkgs.unstable.deluge;
    web = {
      enable = true;
      openFirewall = true;
    };
  };

  services.caddy = {
    enable = true;
    package = pkgs.myCaddy;
    virtualHosts."home.husbuddies.gay" = {
      hostName = "home.husbuddies.gay";
      serverAliases = [ "192.168.1.200" "127.0.0.1" "localhost" ];
      listenAddresses = [ "127.0.0.1" "localhost" "::1" ];
      extraConfig = ''
        respond "Hello, world!"
      '';
    };
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      flaresolverr = {
        image = "flaresolverr/flaresolverr:v3.3.6";
        ports = [
          "8191:8191"
        ];
      };
      homepage = {
        image = "ghcr.io/benphelps/homepage:v0.6.35";
        ports = [
          "3000:3000"
        ];
        volumes = [

        ];
      };
    };
  };


  services.rpcbind.enable = true;

  # Mount filesystems
  fileSystems = {
    "/mnt/video" = {
      device = "192.168.1.100:/volume1/video";
      fsType = "nfs";
    };
    "/mnt/music" = {
      device = "192.168.1.100:/volume1/music";
      fsType = "nfs";
    };
    "/mnt/books" = {
      device = "192.168.1.100:/volume1/books";
      fsType = "nfs";
    };
  };

  # Environment
  environment = {
    pathsToLink = [ "/share/zsh" ];

    systemPackages = with pkgs.unstable; [
      polkit
      pciutils
      hwdata
      cachix
      docker-compose
      tailscale
    ];

    loginShellInit = ''
      eval $(ssh-agent)
    '';
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
