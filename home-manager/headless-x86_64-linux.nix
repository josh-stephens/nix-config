{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix
    ./tmux
    ./devspaces-host
  ];

  home = {
    homeDirectory = "/home/joshsymonds";

    packages = with pkgs; [
      file
      unzip
      dmidecode
      gcc
    ];
  };

  programs.zsh.shellAliases.update = "sudo nixos-rebuild switch --flake \".#$(hostname)\"";

  systemd.user.startServices = "sd-switch";
}
