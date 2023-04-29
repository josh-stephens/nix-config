# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{ inputs, lib, config, pkgs, ... }: {
  # You can import other home-manager modules here
  imports = [
    inputs.nixneovim.nixosModules.default

    # If you want to use home-manager modules from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModule

    # You can also split up your configuration and import pieces of it here:
    ./hyprland
    ./nvim
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      inputs.nixpkgs-wayland.overlay
      inputs.nixneovim.overlays.default
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

  # TODO: Set your username
  home = {
    username = "joshsymonds";
    homeDirectory = "/home/joshsymonds";

    packages = with pkgs; [ 
      discord
      mako
      ranger
      tofi
      bat
      exa
      jq
      spotify
      spotifywm
      polkit-kde-agent
      catppuccin-cursors.macchiatoPink
      xivlauncher
      steam
      unstable._1password-gui
      inputs.nixpkgs-wayland.packages.${system}.wl-clipboard
    ];
  };

  # Programs
  programs.mako = {
    enable = true;
  };
  programs.kitty.enable = true;
  programs.go.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  xdg.configFile."mako/config".source = ./mako/config;
  xdg.configFile."kitty/kitty.conf".source = ./kitty/kitty.conf;
  xdg.configFile."zsh" = {
    source = ./zsh/zsh;
    recursive = true;
  };

  home.file.".zshrc".source = ./zsh/.zshrc;
  home.file.".zshenv".source = ./zsh/.zshenv;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.11";
}
