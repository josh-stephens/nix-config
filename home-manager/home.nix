# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{ inputs, lib, config, pkgs, ... }: {
  nixpkgs = {
    # You can add overlays here
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      (final: prev: {
        unstable = import inputs.nixpkgs-unstable {
          system = final.system;
          config.allowUnfree = true;

          # Add unstable overlays
          overlays = [
            (final: prev: {
              waybar = prev.waybar.overrideAttrs (oldAttrs: {
                mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
              });
            })
          ];
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

  # You can import other home-manager modules here
  imports = [
    # You can also split up your configuration and import pieces of it here:
    ./nvim
    ./git
    ./kitty
    ./k9s
    ./wlogout
    ./zsh
    ./starship
    inputs.webcord.homeManagerModules.default
  ] ++ stdenv.isDarwin [
    ./skhd
    ./yabai
  ] ++ stdenv.isLinux [
    ./wofi
    ./waybar
    ./hyprland
  ];

  # TODO: Set your username
  home = {
    username = "joshsymonds";
    homeDirectory = "/home/joshsymonds";

    packages = with pkgs; [ 
      ranger
      bat
      exa
      jq
      catppuccin-cursors.mochaLavender
      xdg-utils
      spotify
      unstable.firefox
      unstable.signal-desktop-beta
      unstable.slack
      unstable.vivid
      fzf
    ] ++ stdenv.isDarwin [
      inputs.nixpkgs-wayland.packages.${system}.wl-clipboard
      unstable.hyprpicker
      swaybg
      swaylock-effects
      swayidle
      psensor
      unstable.piper
    ] ++ stdenv.IsLinux [
      spotifywm
      polkit-kde-agent
      xivlauncher
      steam
      unstable.pavucontrol
      unstable._1password-gui
      inputs.webcord.packages.${system}.default
      unstable.qbittorrent
    ];

    pointerCursor = {
      name = "Catppuccin-Mocha-Lavender-Cursors";
      package = pkgs.catppuccin-cursors.mochaLavender;
      gtk.enable = true;
      size = 20;
    };
  };

  # Programs
  programs.go.enable = true;

  programs.webcord = {
    enable = true;
    themes = let
      catppuccin = pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "discord";
        rev = "159aac939d8c18da2e184c6581f5e13896e11697";
        sha256 = "sha256-cWpog52Ft4hqGh8sMWhiLUQp/XXipOPnSTG6LwUAGGA=";
      };
    in {
      CatpuccinMocha = "${catppuccin}/themes/mocha.theme.css";
    };
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  xdg.enable = true;

  home.file."Backgrounds" = {
    source = ./Backgrounds;
    recursive = true;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.11";
}
