{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix
    # ./media.nix
    ./tmux
    ./devspaces-host
    ./claude-wrapper
    ./clipboard-sync
  ];

  home = {
    homeDirectory = "/home/joshsymonds";

    packages = with pkgs; [
      file
      unzip
      dmidecode
      gcc  # C compiler for Neovim plugins (TreeSitter, etc.)
    ];
  };

  programs.zsh.shellAliases.update = "sudo nixos-rebuild switch --flake \".#$(hostname)\"";
  
  # Enable tmux with devspace mode for servers
  programs.tmux-devspace = {
    enable = true;
    devspaceMode = true;
    remoteOpener = true;  # Enable remote link opening
  };

  # Enable devspaces management
  programs.devspaces = {
    enable = true;
    claudeNotifications = true;
  };

  # Enable Claude wrapper
  programs.claude-wrapper = {
    enable = true;
  };

  # Enable clipboard sync for remote development
  programs.clipboard-sync = {
    enable = true;
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
