{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix

    ./eww
    ./kitty
    ./wofi
    ./hyprland
    ./wlogout
    ./swaync
    ./firefox
  ];

  home = {
    homeDirectory = "/home/joshsymonds";

    packages = with pkgs.unstable; [
      appimage-run
      spotifywm
      (pkgs.makeDesktopItem {
        name = "Spotify";
        exec = "spotifywm";
        desktopName = "Spotify";
      })
      google-chrome
      inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
      polkit-kde-agent
      file
      steam
      unzip
      cliphist
      wl-clip-persist
      pavucontrol
      (pkgs.writeShellApplication {
        name = "discord";
        text = "${pkgs.unstable.discord}/bin/discord --use-gl=desktop --enable-features=UseOzonePlatform --ozone-platform=wayland";
      })
      (pkgs.makeDesktopItem {
        name = "discord";
        exec = "discord";
        desktopName = "Discord";
      })
      nvtop
      qbittorrent
      inputs.nixpkgs-wayland.packages.${system}.wl-clipboard
      hyprpicker
      swaylock-effects
      swayidle
      swww
      piper
      catppuccin-cursors.mochaLavender
      signal-desktop-beta
      slack
      xclip
      inputs.nix-gaming.packages.${system}.wine-ge
    ];

    pointerCursor = {
      name = "Catppuccin-Mocha-Lavender-Cursors";
      package = pkgs.catppuccin-cursors.mochaLavender;
      gtk.enable = true;
      size = 20;
    };
  };

  gtk = {
    enable = true;
    font.name = "Maple Mono NF CN";
    theme = {
      name = "Catppuccin-Mocha-Compact-Lavender-Dark";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "lavender" ];
        size = "compact";
        tweaks = [ "rimless" ];
        variant = "mocha";
      };
    };
  };

  programs.zsh.shellAliases.update = "sudo nixos-rebuild switch --flake \".#$(hostname)\"";
  programs.kitty.font.size = 10;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
