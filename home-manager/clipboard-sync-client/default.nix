{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.clipboard-sync-client;
  
  # Piknik client configuration for macOS
  piknikConfig = ''
    # Connect to the Linux server
    Connect = "ultraviolet:8075"
  '';
  
in {
  options.programs.clipboard-sync-client = {
    enable = mkEnableOption "clipboard synchronization client (for macOS)";
  };

  config = mkIf cfg.enable {
    # Install piknik
    home.packages = [ pkgs.piknik ];
    
    # Don't manage piknik config - let user set it up manually
    
    # Just use the generated piknik config directly
    # User should run: piknik -genkeys > ~/.piknik.toml
    home.activation.piknikConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -f "$HOME/.piknik.toml" ]; then
        $VERBOSE_ECHO "Warning: ~/.piknik.toml not found."
        $VERBOSE_ECHO "To set up piknik, run:"
        $VERBOSE_ECHO "  piknik -genkeys > ~/.piknik.toml"
        $VERBOSE_ECHO ""
        $VERBOSE_ECHO "Then edit ~/.piknik.toml:"
        $VERBOSE_ECHO "  - On Mac (server): Keep the 'Configuration for a server' section"
        $VERBOSE_ECHO "  - On Linux (client): Keep the 'Configuration for a client' section"
        $VERBOSE_ECHO "  - Delete the other section"
        $VERBOSE_ECHO "  - Change Connect = line to point to your server (e.g., cloudbank:8075)"
        $VERBOSE_ECHO ""
        $VERBOSE_ECHO "Finally, copy the SAME keys to all machines (just the key values)."
      fi
    '';
    
    # No server needed on Mac - it's a client
    
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
      
      initContent = ''
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