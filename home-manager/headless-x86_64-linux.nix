{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix
    # ./media.nix
    ./tmux
  ];

  home = {
    homeDirectory = "/home/joshsymonds";

    packages = with pkgs; [
      file
      unzip
      dmidecode
    ];
  };

  programs.zsh.shellAliases.update = "sudo nixos-rebuild switch --flake \".#$(hostname)\"";
  
  # Enable tmux with planet mode for servers
  programs.tmux-planet = {
    enable = true;
    planetMode = true;
    remoteOpener = true;  # Enable remote link opening
    claudeNotifications = true;  # Enable Claude notification wrapper
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
