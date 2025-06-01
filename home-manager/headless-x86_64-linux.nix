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
      gcc  # C compiler for Neovim plugins (TreeSitter, etc.)
      xclip  # Clipboard support for SSH sessions
      wl-clipboard  # Wayland clipboard support (also works in SSH)
    ];
  };

  programs.zsh.shellAliases.update = "sudo nixos-rebuild switch --flake \".#$(hostname)\"";
  
  # Enable tmux with devspace mode for servers
  programs.tmux-devspace = {
    enable = true;
    devspaceMode = true;
    remoteOpener = true;  # Enable remote link opening
    claudeNotifications = true;  # Enable Claude notification wrapper
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
