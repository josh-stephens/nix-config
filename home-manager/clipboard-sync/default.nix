{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.clipboard-sync;
  wrappers = import ./clipboard-wrappers.nix { inherit pkgs; };
  
in {
  options.programs.clipboard-sync = {
    enable = mkEnableOption "clipboard synchronization for remote development";
  };

  config = mkIf cfg.enable {
    # Install piknik and clipboard wrappers
    home.packages = [ pkgs.piknik ] ++ wrappers.home.packages;
    
    # Don't manage piknik config - let user set it up manually
    # User should create ~/.piknik.toml with appropriate server/client config
    
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
          # Try piknik first with timeout
          if [ -t 0 ]; then
            # If no stdin, copy arguments
            if echo -n "$*" | timeout 0.5 piknik -copy 2>/dev/null; then
              return 0
            else
              # Fallback to OSC52
              printf "\033]52;c;$(echo -n "$*" | base64)\a"
            fi
          else
            # Copy from stdin
            if timeout 0.5 piknik -copy 2>/dev/null; then
              return 0
            else
              # Fallback to OSC52
              printf "\033]52;c;$(base64)\a"
            fi
          fi
        }
        
        # No need for aliases - we have proper wrapper scripts in PATH
        
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