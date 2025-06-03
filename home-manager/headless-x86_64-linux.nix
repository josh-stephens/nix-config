{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix
    # ./media.nix
    ./tmux-simplified
    ./claude-wrapper
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
  
  programs.tmux-simple = {
    enable = true;
    remoteOpener = true;
  };

  programs.claude-wrapper = {
    enable = true;
  };

  systemd.user.startServices = "sd-switch";
}
