{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix
    # ./media.nix
    ./tmux
    ./devspaces
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
  
  # Auto-connect to devspace if marker file exists
  programs.zsh.initContent = ''
    # Check for devspace auto-connect marker
    if [ -f ~/.devspace-autoconnect ] && [ -z "$TMUX" ]; then
      devspace=$(cat ~/.devspace-autoconnect)
      rm -f ~/.devspace-autoconnect
      if command -v "$devspace" &>/dev/null; then
        # Run the devspace command to attach to tmux
        exec "$devspace"
      fi
    fi
  '';
  
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
