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
      # Integration/automation specific tools
      jq
      httpie
      websocat  # WebSocket client
    ];
  };

  programs.zsh.shellAliases.update = "sudo nixos-rebuild switch --flake \".#$(hostname)\"";

  systemd.user.startServices = "sd-switch";
}