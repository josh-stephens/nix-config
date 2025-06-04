{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.claude-wrapper;

  # macOS idle detection using ioreg
  claudeNotifyDarwin = pkgs.writeScriptBin "claude-notify" ''
    #!${pkgs.bash}/bin/bash
    # 🔔 Claude Code wrapper for macOS with idle detection
    
    set -euo pipefail
    
    # Configuration
    NFTY_TOPIC="CUFVGE2uFcTRl7Br"
    NFTY_SERVER="https://ntfy.sh"
    LOG_FILE="$HOME/.claude-code.log"
    IDLE_TIMEOUT="''${CLAUDE_IDLE_TIMEOUT:-120}"  # Default 2 minutes
    
    # 📝 Log function
    log() {
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    }
    
    # 🔍 Check if user is idle (macOS specific)
    is_user_idle() {
      # Get system idle time in seconds
      local idle_time=$(($(ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print int($NF/1000000000); exit}')))
      
      if [ $idle_time -gt $IDLE_TIMEOUT ]; then
        log "User idle for $idle_time seconds"
        return 0
      fi
      return 1
    }
    
    # 📨 Send notification
    send_notification() {
      local title="$1"
      local message="$2"
      local priority="''${3:-default}"
      local tags="''${4:-}"
      
      # Skip notifications if user is active unless forced
      if [ -z "''${CLAUDE_FORCE_NOTIFY:-}" ] && ! is_user_idle; then
        log "Notification suppressed (user active): $title"
        return
      fi
      
      ${pkgs.curl}/bin/curl -s \
        -H "Title: $title" \
        -H "Priority: $priority" \
        -H "Tags: $tags" \
        -d "$message" \
        "$NFTY_SERVER/$NFTY_TOPIC" > /dev/null || true
      
      log "Notification sent: $title - $message"
    }
    
    # Monitor script (simplified for macOS)
    MONITOR_SCRIPT="/tmp/claude-monitor-$$.sh"
    cat > "$MONITOR_SCRIPT" << 'MONITOR_EOF'
#!/bin/bash
LOG_FILE="$1"
NFTY_TOPIC="$2"
NFTY_SERVER="$3"
IDLE_TIMEOUT="$4"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] MONITOR: $1" >> "$LOG_FILE"
}

is_user_idle() {
  local idle_time=$(($(ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print int($NF/1000000000); exit}')))
  [ $idle_time -gt $IDLE_TIMEOUT ]
}

send_notification() {
  local title="$1"
  local message="$2"
  local priority="''${3:-default}"
  local tags="''${4:-}"
  
  if [ -z "''${CLAUDE_FORCE_NOTIFY:-}" ] && ! is_user_idle; then
    log "Notification suppressed (user active): $title"
    return
  fi
  
  curl -s \
    -H "Title: $title" \
    -H "Priority: $priority" \
    -H "Tags: $tags" \
    -d "$message" \
    "$NFTY_SERVER/$NFTY_TOPIC" > /dev/null || true
  
  log "Notification sent: $title"
}

while IFS= read -r line; do
  printf '%s\n' "$line"
  
  clean_line=$(printf '%s' "$line" | sed 's/\x1b\[[0-9;]*m//g')
  log "OUTPUT: $clean_line"
  
  # Bell detection
  if printf '%s' "$line" | grep -q $'\a'; then
    log "Bell detected!"
    send_notification \
      "🔔 Claude needs attention" \
      "Claude is requesting your input" \
      "high" \
      "bell,claude"
  fi
  
  # Question detection
  if [[ "$clean_line" =~ \?[[:space:]]*$ ]]; then
    log "Question detected: $clean_line"
    send_notification \
      "❓ Claude has a question" \
      "$clean_line" \
      "default" \
      "question,claude"
  fi
  
  # Completion detection
  if [[ "$clean_line" =~ (completed|done|finished)[[:punct:]]*$ ]]; then
    log "Completion detected: $clean_line"
    send_notification \
      "✅ Claude task completed" \
      "$clean_line" \
      "default" \
      "done,claude"
  fi
done
MONITOR_EOF

    chmod +x "$MONITOR_SCRIPT"
    
    # Start claude with monitoring
    log "Starting Claude Code wrapper"
    
    send_notification \
      "🚀 Claude starting" \
      "Claude Code is initializing" \
      "low" \
      "start,claude"
    
    CLAUDE_PATH="$HOME/.npm-global/bin/claude"
    
    # Use script command for proper terminal handling
    ${pkgs.util-linux}/bin/script -e -q -c "
      '$CLAUDE_PATH' $* 2>&1 | '$MONITOR_SCRIPT' '$LOG_FILE' '$NFTY_TOPIC' '$NFTY_SERVER' '$IDLE_TIMEOUT'
    " /dev/null
    
    CLAUDE_EXIT=$?
    rm -f "$MONITOR_SCRIPT"
    
    if [ $CLAUDE_EXIT -eq 0 ]; then
      send_notification \
        "👋 Claude stopped" \
        "Claude Code exited normally" \
        "low" \
        "stop,claude"
    else
      send_notification \
        "💥 Claude crashed" \
        "Claude Code exited with code $CLAUDE_EXIT" \
        "urgent" \
        "crash,claude"
    fi
    
    exit $CLAUDE_EXIT
  '';

in {
  options.programs.claude-wrapper = {
    enable = mkEnableOption "Claude Code wrapper with notifications";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      claudeNotifyDarwin
    ];

    # Override the claude command on macOS
    programs.zsh.shellAliases = {
      claude = "claude-notify";
    };
  };
}