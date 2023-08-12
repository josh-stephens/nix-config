{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix

    ./kitty
    ./wofi
    ./waybar
    ./hyprland
    ./wlogout
    ./swaync
    ./xiv
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
      csharp-ls
      inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
      polkit-kde-agent
      file
      steam
      unzip
      cliphist
      pavucontrol
      (pkgs.writeShellApplication {
        name = "discord";
        text = "${pkgs.unstable.discord}/bin/discord --use-gl=desktop";
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
      swaybg
      swaylock-effects
      swayidle
      psensor
      piper
      catppuccin-cursors.mochaLavender
      signal-desktop-beta
      slack
      xclip
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
  programs.nixneovim.plugins.lsp.servers.csharp_ls.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
