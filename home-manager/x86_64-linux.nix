{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix

    ./wofi
    ./waybar
    ./hyprland
    ./wlogout
    inputs.webcord.homeManagerModules.default
  ];

  home = {
    homeDirectory = "/home/joshsymonds";

    packages = with pkgs; [ 
      spotifywm
      polkit-kde-agent
      xivlauncher
      steam
      unstable.pavucontrol
      unstable._1password-gui
      inputs.webcord.packages.${system}.default
      unstable.qbittorrent
      inputs.nixpkgs-wayland.packages.${system}.wl-clipboard
      unstable.hyprpicker
      swaybg
      swaylock-effects
      swayidle
      psensor
      unstable.piper
      spotify
      catppuccin-cursors.mochaLavender
      unstable.firefox
      unstable.signal-desktop-beta
      unstable.slack
    ];

    pointerCursor = {
      name = "Catppuccin-Mocha-Lavender-Cursors";
      package = pkgs.catppuccin-cursors.mochaLavender;
      gtk.enable = true;
      size = 20;
    };
  };

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

  programs.zsh.shellAliases.update = "sudo nixos-rebuild switch --flake \".#$(hostname)\"";

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
