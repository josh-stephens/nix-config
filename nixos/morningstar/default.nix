let
  system = "x86_64-linux";
  user = "joshsymonds";
in
{ inputs, outputs, lib, config, pkgs, ... }: {
  # You can import other NixOS modules here
  imports = [
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-pc-ssd
    inputs.hardware.nixosModules.common-gpu-nvidia
    inputs.hyprland.nixosModules.default
    inputs.agenix.nixosModules.default
    # inputs.agenix-rekey.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
    inputs.xremap-flake.nixosModules.default
    inputs.nur.nixosModules.nur

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
  ];

  # Hardware setup
  hardware = {
    cpu = {
      amd.updateMicrocode = true;
    };
    nvidia = {
      prime.offload.enable = false;
      modesetting.enable = true;
    };
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
    enableAllFirmware = true;
  };

  nixpkgs = {
    # You can add overlays here
    overlays = [
      inputs.nixneovim.overlays.default
      inputs.nur.overlay
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
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
        "https://hyprland.cachix.org"
        "https://cache.nixos.org"
        "https://nixpkgs-wayland.cachix.org"
        "https://nix-gaming.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      ];
    };
  };

  networking.hostName = "morningstar";
  networking.firewall.checkReversePath = "loose";

  boot = {
    kernelPackages = pkgs.linuxPackages_xanmod;
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelModules = [ "coretemp" "kvm-intel" "nct6775" ];
    supportedFilesystems = [ "ntfs" ];
    kernelParams = [ "quiet" "splash" "rd.systemd.show_status=false" "rd.udev.log_level=3" "udev.log_priority=3" "boot.shell_on_fail" ];
    plymouth = {
      enable = true;
    };
    loader = {
      timeout = 2;
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot/efi";
    };
  };

  fileSystems."/mnt/windows" = {
    device = "/dev/sda2";
    fsType = "ntfs3";
  };

  # Time and internationalization
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # Default programs everyone wants
  virtualisation.docker.enable = true;
  programs._1password-gui = {
    enable = true;
    package = pkgs.unstable._1password-gui.override
      ({
        channel = "beta";
      });
    polkitPolicyOwners = [ "${user}" ];
  };
  programs._1password = {
    enable = true;
    package = pkgs.unstable._1password;
  };
  programs.gamemode.enable = true;

  # Users and their homes
  users.defaultUserShell = pkgs.zsh;
  users.users.${user} = {
    shell = pkgs.unstable.zsh;
    home = "/home/${user}";
    initialPassword = "correcthorsebatterystaple";
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAQ4hwNjF4SMCeYcqm3tzUxZWadcv7ZLJbCa/mLHzsvw josh+cloudbank@joshsymonds.com"
    ];
    extraGroups = [ "wheel" config.users.groups.keys.name "docker" ];
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
  security = {
    rtkit.enable = true;
    polkit.enable = true;
    pam = {
      services.swaylock = {
        text = ''
          auth sufficient pam_yubico.so mode=challenge-response
          auth include login
        '';
      };
      yubico = {
        enable = true;
        mode = "challenge-response";
      };
    };
  };

  # Services
  services.thermald.enable = true;
  services.pcscd.enable = true;
  services.ratbagd.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  services.getty.autologinUser = "${user}";

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
  programs.ssh.startAgent = true;

  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "Hyprland";
        user = "${user}";
      };
      default_session = initial_session;
    };
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

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

  programs.zsh.enable = true;
  programs.sway.enable = true;

  # Fonts!
  fonts = {
    fonts = with pkgs;
      [
        (nerdfonts.override {
          fonts = [ "NerdFontsSymbolsOnly" ];
        })
      ];

    fontconfig = {
      antialias = true;
      hinting = {
        enable = true;
        style = "hintfull";
        autohint = true;
      };
      subpixel.rgba = "rgb";
      defaultFonts = {
        monospace = [ "Cartograph CF Regular" "Symbols Nerd Font Mono" ];
      };
    };
  };

  # Environment
  environment = {
    pathsToLink = [ "/share/zsh" ];

    sessionVariables = rec {
      GBM_BACKEND = "nvidia-drm";
      __GL_GSYNC_ALLOWED = "0";
      __GL_VRR_ALLOWED = "0";
      WLR_DRM_NO_ATOMIC = "1";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";

      # Will break SDDM if running X11
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

      GDK_BACKEND = "wayland";
      WLR_NO_HARDWARE_CURSORS = "1";
      MOZ_ENABLE_WAYLAND = "1";
      NIXOS_OZONE_WL = "1";
    };

    systemPackages = with pkgs.unstable; [
      polkit
      polkit_gnome
      pciutils
      hwdata
      yubikey-manager
      yubico-pam
      cachix
      speechd
      sox
    ];

    etc."greetd/environments".text = ''
      Hyprland
    '';
    etc."sysconfig/lm_sensors".text = ''
      # This file is sourced by /etc/init.d/lm_sensors and defines the modules to
      # be loaded/unloaded.
      #
      # The format of this file is a shell script that simply defines variables:
      # HWMON_MODULES for hardware monitoring driver modules, and optionally
      # BUS_MODULES for any required bus driver module (for example for I2C or SPI).

      HWMON_MODULES="nct6775"
    '';
    loginShellInit = ''
      eval $(ssh-agent)
    '';
  };

  # xdg
  xdg.portal = {
    enable = true;
    wlr.enable = false;
    extraPortals = [
      inputs.xdg-portal-hyprland.packages.${system}.default
    ];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
