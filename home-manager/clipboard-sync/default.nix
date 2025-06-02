{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.clipboard-sync;
  
  # Piknik configuration - this machine runs as SERVER
  piknikConfig = ''
    # This Linux server hosts the clipboard
    Listen = "0.0.0.0:8075"
  '';
  
in {
  options.programs.clipboard-sync = {
    enable = mkEnableOption "clipboard synchronization for remote development";
  };

  config = mkIf cfg.enable {
    # Install piknik
    home.packages = [ pkgs.piknik ];
    
    # Don't manage piknik config - let user set it up manually
    
    # Script to merge key file with config
    home.activation.piknikConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ -f "$HOME/.piknik.toml.key" ]; then
        # Merge the key file with the generated config
        $DRY_RUN_CMD cat ${pkgs.writeText "piknik-base.toml" piknikConfig} > $HOME/.piknik.toml.tmp
        $DRY_RUN_CMD echo "" >> $HOME/.piknik.toml.tmp
        $DRY_RUN_CMD cat $HOME/.piknik.toml.key >> $HOME/.piknik.toml.tmp
        $DRY_RUN_CMD mv $HOME/.piknik.toml.tmp $HOME/.piknik.toml
      else
        $VERBOSE_ECHO "Warning: ~/.piknik.toml.key not found. Run 'piknik -genkeys > ~/.piknik.toml.key' to generate it."
      fi
    '';
    
    # Shell configuration for clipboard commands
    programs.zsh = {
      shellAliases = {
        # Clipboard aliases
        pc = "piknik -copy";
        pp = "piknik -paste";
        pm = "piknik -move";  # Cut operation
        pz = "piknik -copy < /dev/null";  # Clear clipboard
        
        # Compatibility aliases
        clip = "piknik -copy";
        paste = "piknik -paste";
      };
      
      # Shell functions for better clipboard integration
      initExtra = ''
        # Copy function that works with pipes or arguments
        copy() {
          if [ -t 0 ]; then
            # If no stdin, copy arguments
            echo -n "$*" | piknik -copy
          else
            # Copy from stdin
            piknik -copy
          fi
        }
        
        # Override system clipboard commands if in SSH/tmux
        if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ] || [ -n "$TMUX" ]; then
          # Linux clipboard aliases that use piknik
          alias xclip="piknik -copy"
          alias xsel="piknik -copy"
          alias pbcopy="piknik -copy"
          alias pbpaste="piknik -paste"
          
          # Also handle wl-clipboard commands for Wayland
          alias wl-copy="piknik -copy"
          alias wl-paste="piknik -paste"
        fi
        
        # Quick copy last command
        copy-last() {
          fc -ln -1 | piknik -copy
          echo "Copied last command to clipboard"
        }
        
        # Copy current directory path
        copy-pwd() {
          pwd | piknik -copy
          echo "Copied current directory to clipboard"
        }
        
        # Copy file content
        copy-file() {
          if [ -f "$1" ]; then
            piknik -copy < "$1"
            echo "Copied $1 to clipboard"
          else
            echo "File not found: $1"
            return 1
          fi
        }
        
        # Paste to file
        paste-to() {
          if [ -z "$1" ]; then
            echo "Usage: paste-to <filename>"
            return 1
          fi
          piknik -paste > "$1"
          echo "Pasted clipboard to $1"
        }
      '';
    };
    
    # Configure tmux to use piknik for copy operations
    programs.tmux.extraConfig = mkIf config.programs.tmux-devspace.enable ''
      # Use piknik for copy operations
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "piknik -copy"
      bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "piknik -copy"
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "piknik -copy"
      
      # Additional bindings for paste
      bind-key p run-shell "piknik -paste | tmux load-buffer -" \; paste-buffer
    '';
    
    # Note: Neovim clipboard integration is handled in the nvim module
    # to avoid conflicts with the managed config directory
    
    # Systemd service to run piknik server
    systemd.user.services.piknik-server = mkIf (pkgs.stdenv.isLinux) {
      Unit = {
        Description = "Piknik clipboard server";
        After = [ "network.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.piknik}/bin/piknik -server";
        Restart = "always";
        RestartSec = 10;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}