{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix
    ./tmux
    ./devspaces-host
    ./security-tools
    ./gmailctl
  ];

  home = {
    homeDirectory = lib.mkDefault "/home/${config.home.username}";

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
