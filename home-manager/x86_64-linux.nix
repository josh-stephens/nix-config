{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix

    ./wofi
    ./waybar
    ./hyprland
    ./wlogout
    ./xiv
  ];

  home = {
    homeDirectory = "/home/joshsymonds";

    packages = with pkgs; [
      spotifywm
      (pkgs.makeDesktopItem {
        name = "Spotify";
        exec = "spotifywm";
        desktopName = "Spotify";
      })
      polkit-kde-agent
      file
      steam
      unzip
      unstable.cliphist
      unstable.pavucontrol
      (pkgs.writeShellApplication {
        name = "discord";
        text = "${pkgs.unstable.discord}/bin/discord --use-gl=desktop";
      })
      (pkgs.makeDesktopItem {
        name = "discord";
        exec = "discord";
        desktopName = "Discord";
      })
      unstable.nvtop
      unstable.qbittorrent
      inputs.nixpkgs-wayland.packages.${system}.wl-clipboard
      unstable.hyprpicker
      swaybg
      swaylock-effects
      swayidle
      psensor
      unstable.piper
      catppuccin-cursors.mochaLavender
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

  programs.zsh.shellAliases.update = "sudo nixos-rebuild switch --flake \".#$(hostname)\"";
  programs.kitty.font.size = 10;
  programs.kitty.settings."kitty_mod" = "alt";

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
