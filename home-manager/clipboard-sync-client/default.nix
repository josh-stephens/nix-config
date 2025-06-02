{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.clipboard-sync-client;
  
  # Piknik server configuration for macOS - reads key from ~/.piknik.toml.key
  piknikConfig = ''
    # Listen on all interfaces for Tailscale connections
    listen = "0.0.0.0:8075"
    
    # Connection timeout
    connect_timeout = 3
    
    # Clipboard timeout (5 minutes)
    timeout = 300
    
    # Max clipboard size (10MB)
    max_size = 10485760
  '';
  
in {
  options.programs.clipboard-sync-client = {
    enable = mkEnableOption "clipboard synchronization server (for macOS)";
  };

  config = mkIf cfg.enable {
    # Install piknik
    home.packages = [ pkgs.piknik ];
    
    # Piknik configuration
    home.file.".piknik.toml".text = piknikConfig;
    
    # Script to merge key file with config
    home.activation.piknikConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ -f "$HOME/.piknik.toml.key" ]; then
        # Merge the key file with the generated config
        $DRY_RUN_CMD cat ${pkgs.writeText "piknik-base.toml" piknikConfig} > $HOME/.piknik.toml.tmp
        $DRY_RUN_CMD echo "" >> $HOME/.piknik.toml.tmp
        $DRY_RUN_CMD cat $HOME/.piknik.toml.key >> $HOME/.piknik.toml.tmp
        $DRY_RUN_CMD mv $HOME/.piknik.toml.tmp $HOME/.piknik.toml
      else
        $VERBOSE_ECHO "Warning: ~/.piknik.toml.key not found. First run:"
        $VERBOSE_ECHO "  piknik -genkeys | grep '^key =' > ~/.piknik.toml.key"
        $VERBOSE_ECHO "Then copy ~/.piknik.toml.key to all your machines."
      fi
    '';
    
    # Create launchd service for piknik server on macOS
    launchd.agents.piknik = {
      enable = true;
      config = {
        Label = "com.piknik.server";
        ProgramArguments = [
          "${pkgs.piknik}/bin/piknik"
          "-server"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/piknik.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/piknik.error.log";
        EnvironmentVariables = {
          PATH = "${pkgs.piknik}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          HOME = config.home.homeDirectory;
        };
      };
    };
    
    # Shell configuration for local clipboard testing and management
    programs.zsh = {
      shellAliases = {
        # Server management
        piknik-status = "lsof -i :8075 || echo 'Piknik server not running'";
        piknik-logs = "tail -f ~/Library/Logs/piknik.log";
        piknik-errors = "tail -f ~/Library/Logs/piknik.error.log";
        
        # Generate new keys
        piknik-genkeys = "piknik -genkeys";
      };
      
      initExtra = ''
        # Start piknik server if not running (backup for launchd)
        start-piknik() {
          if ! lsof -i :8075 >/dev/null 2>&1; then
            echo "Starting piknik server..."
            piknik -server &
            disown
            sleep 1
            echo "Piknik server started on port 8075"
          else
            echo "Piknik server already running"
          fi
        }
        
        # Test piknik locally
        piknik-test() {
          echo "Testing piknik clipboard sync..." | piknik -copy && \
          echo "Copied test message. Pasting:" && \
          piknik -paste
        }
        
        # Mac clipboard integration functions
        # Copy from Mac clipboard to piknik
        mac-to-piknik() {
          pbpaste | piknik -copy
          echo "Mac clipboard synced to piknik"
        }
        
        # Copy from piknik to Mac clipboard
        piknik-to-mac() {
          piknik -paste | pbcopy
          echo "Piknik clipboard synced to Mac"
        }
        
        # Two-way sync helper
        sync-clipboard() {
          case "''${1:-}" in
            push|up|mac)
              mac-to-piknik
              ;;
            pull|down|piknik)
              piknik-to-mac
              ;;
            *)
              echo "Usage: sync-clipboard [push|pull]"
              echo "  push/up/mac    - Copy Mac clipboard to piknik"
              echo "  pull/down/piknik - Copy piknik to Mac clipboard"
              ;;
          esac
        }
      '';
    };
  };
}