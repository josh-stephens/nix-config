{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ../common.nix
    ../tmux
    ../devspaces-host
    ../linkpearl
    ../security-tools
  ];

  home = {
    homeDirectory = "/home/joshsymonds";

    packages = with pkgs; [
      file
      unzip
      dmidecode
      gcc
      # Download server specific tools
      aria2
      yt-dlp
    ];
  };

  programs.zsh.shellAliases.update = "sudo nixos-rebuild switch --flake \".#$(hostname)\"";

  systemd.user.startServices = "sd-switch";
}