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
  
  # Auto-connect to devspace based on DEVSPACE_ID environment variable
  programs.zsh.initContent = ''
    # Check if DEVSPACE_ID is set (from ET connection)
    if [ -n "$DEVSPACE_ID" ] && [ -z "$TMUX" ]; then
      # Attach to the corresponding tmux session
      session="devspace-$DEVSPACE_ID"
      if tmux has-session -t "$session" 2>/dev/null; then
        exec tmux attach-session -t "$session"
      else
        # Session doesn't exist, create it first
        # Get devspace name from ID
        case "$DEVSPACE_ID" in
          ${lib.concatStringsSep "\n          " (map (s: ''${toString s.id}) devspace_name="${s.name}" ;;'') theme.spaces)}
          *) devspace_name="unknown" ;;
        esac
        
        # Run the devspace command to initialize and attach
        if command -v "$devspace_name" &>/dev/null; then
          exec "$devspace_name"
        else
          echo "⚠️  Devspace $devspace_name (ID: $DEVSPACE_ID) not found"
        fi
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
