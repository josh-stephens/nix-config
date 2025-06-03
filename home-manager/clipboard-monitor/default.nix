{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.clipboard-monitor;
  
  # macOS clipboard monitor that syncs to piknik
  clipboardMonitor = pkgs.writeScriptBin "clipboard-monitor" ''
    #!${pkgs.bash}/bin/bash
    
    # Monitor macOS clipboard and sync changes to piknik
    echo "🔄 Starting clipboard monitor..."
    echo "📋 Monitoring system clipboard for changes"
    
    # Store the last known clipboard content
    last_clipboard=""
    
    while true; do
      # Get current clipboard content
      current_clipboard=$(pbpaste 2>/dev/null || echo "")
      
      # Check if clipboard has changed
      if [ "$current_clipboard" != "$last_clipboard" ] && [ -n "$current_clipboard" ]; then
        # Try to sync to piknik with timeout (non-blocking)
        (
          # Debug: log what we're trying
          echo "[DEBUG] Attempting to sync $(echo "$current_clipboard" | wc -c) bytes"
          echo "[DEBUG] PATH=$PATH"
          echo "[DEBUG] HOME=$HOME"
          echo "[DEBUG] Looking for config at: $HOME/.piknik.toml"
          
          # Try with explicit config path and capture stderr
          if echo "$current_clipboard" | ${pkgs.coreutils}/bin/timeout 2 ${pkgs.piknik}/bin/piknik -config "$HOME/.piknik.toml" -copy 2>&1; then
            echo "✅ Synced clipboard to piknik ($(echo "$current_clipboard" | wc -c) bytes)"
          else
            exit_code=$?
            echo "⚠️  Piknik sync failed (exit code: $exit_code)"
            echo "[DEBUG] Trying to cat config file..."
            ls -la "$HOME/.piknik.toml" 2>&1 || echo "[DEBUG] Config file not found!"
          fi
        ) &
        # Update last known clipboard immediately (don't wait for piknik)
        last_clipboard="$current_clipboard"
      fi
      
      # Check every 0.5 seconds
      sleep 0.5
    done
  '';
  
  # Reverse sync: piknik to Mac clipboard
  reverseClipboardMonitor = pkgs.writeScriptBin "reverse-clipboard-monitor" ''
    #!${pkgs.bash}/bin/bash
    
    # Monitor piknik for changes and sync to Mac clipboard
    echo "🔄 Starting reverse clipboard monitor..."
    echo "📋 Monitoring piknik for clipboard changes"
    
    # Store the last known piknik content
    last_piknik=""
    
    while true; do
      # Get current piknik content
      current_piknik=$(${pkgs.piknik}/bin/piknik -paste 2>/dev/null || echo "")
      
      # Check if piknik has changed
      if [ "$current_piknik" != "$last_piknik" ] && [ -n "$current_piknik" ]; then
        # Check if it's different from Mac clipboard
        mac_clipboard=$(pbpaste 2>/dev/null || echo "")
        if [ "$current_piknik" != "$mac_clipboard" ]; then
          # Sync to Mac clipboard
          echo "$current_piknik" | pbcopy
          echo "✅ Synced piknik to Mac clipboard ($(echo "$current_piknik" | wc -c) bytes)"
          last_piknik="$current_piknik"
        fi
      fi
      
      # Check every 1 second (less frequent to avoid conflicts)
      sleep 1
    done
  '';

in {
  options.programs.clipboard-monitor = {
    enable = mkEnableOption "automatic clipboard synchronization between macOS and piknik";
  };

  config = mkIf cfg.enable {
    # Install monitor scripts
    home.packages = [ 
      clipboardMonitor 
      reverseClipboardMonitor 
    ];
    
    # Create launchd service for clipboard monitoring
    launchd.agents.clipboard-monitor = {
      enable = true;
      config = {
        Label = "com.clipboard.monitor";
        ProgramArguments = [
          "${clipboardMonitor}/bin/clipboard-monitor"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/clipboard-monitor.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/clipboard-monitor.error.log";
        EnvironmentVariables = {
          PATH = "${pkgs.piknik}/bin:${pkgs.coreutils}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          HOME = config.home.homeDirectory;
          USER = config.home.username or "joshsymonds";
        };
      };
    };
    
    # Optional: reverse sync service (piknik to Mac)
    # Disabled by default to avoid conflicts
    launchd.agents.reverse-clipboard-monitor = {
      enable = false;  # Enable manually if needed
      config = {
        Label = "com.clipboard.reverse-monitor";
        ProgramArguments = [
          "${reverseClipboardMonitor}/bin/reverse-clipboard-monitor"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/reverse-clipboard-monitor.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/reverse-clipboard-monitor.error.log";
        EnvironmentVariables = {
          PATH = "${pkgs.piknik}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          HOME = config.home.homeDirectory;
        };
      };
    };
    
    # Shell helpers
    programs.zsh = {
      shellAliases = {
        # Monitor control
        clipboard-monitor-status = "launchctl list | grep clipboard.monitor";
        clipboard-monitor-logs = "tail -f ~/Library/Logs/clipboard-monitor.log";
        clipboard-monitor-stop = "launchctl stop com.clipboard.monitor";
        clipboard-monitor-start = "launchctl start com.clipboard.monitor";
        clipboard-monitor-restart = "launchctl stop com.clipboard.monitor && launchctl start com.clipboard.monitor";
      };
    };
  };
}