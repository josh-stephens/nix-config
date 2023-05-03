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
    ];
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

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
