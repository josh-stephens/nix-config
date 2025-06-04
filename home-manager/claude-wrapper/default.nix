{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.claude-wrapper;

  # 🔔 Claude notification wrapper with nfty.sh notifications
  claudeNotifyScript = pkgs.writeScriptBin "claude-notify" ''
    #!${pkgs.bash}/bin/bash
    # 🔔 Claude Code wrapper with nfty.sh notifications
    
    set -euo pipefail
    
    # Configuration
    NFTY_TOPIC="CUFVGE2uFcTRl7Br"
    NFTY_SERVER="https://ntfy.sh"
    DEVSPACE="''${TMUX_DEVSPACE:-unknown}"
    LOG_FILE="$HOME/.claude-code-$DEVSPACE.log"
    IDLE_TIMEOUT="''${CLAUDE_IDLE_TIMEOUT:-120}"  # Default 2 minutes
    
    # 🎨 Color codes for output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
    
    # 📝 Log function
    log() {
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    }
    
    # 🔍 Check if session is attached and active
    is_session_active() {
      if [ -n "$TMUX" ]; then
        # Get session name from TMUX environment
        local session_name=$(${pkgs.tmux}/bin/tmux display-message -p '#S' 2>/dev/null)
        
        # Check if any client is attached to this session
        if ! ${pkgs.tmux}/bin/tmux list-clients -t "$session_name" 2>/dev/null | grep -q .; then
          log "Session not attached"
          return 1
        fi
        
        # Check for recent activity (within last 2 minutes)
        local client_activity=$(${pkgs.tmux}/bin/tmux display-message -p '#{client_activity}' 2>/dev/null || echo "0")
        local current_time=$(date +%s)
        local idle_time=$((current_time - client_activity))
        
        # If idle for more than IDLE_TIMEOUT seconds, consider inactive
        if [ $idle_time -gt $IDLE_TIMEOUT ]; then
          log "Session attached but idle for $idle_time seconds (threshold: $IDLE_TIMEOUT)"
          return 1
        fi
        
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
      
      # Skip notifications if session is attached AND active (user is actively present)
      # unless CLAUDE_FORCE_NOTIFY is set
      if [ -z "''${CLAUDE_FORCE_NOTIFY:-}" ] && is_session_active; then
        log "Notification suppressed (session active): $title"
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
    
    # 🚀 Start Claude Code
    echo -e "''${BLUE}🤖 Starting Claude Code in devspace $DEVSPACE...''${NC}"
    log "Starting Claude Code wrapper with args: $*"
    
    # Send start notification
    send_notification \
      "🚀 $DEVSPACE Claude starting" \
      "Claude Code is initializing in devspace $DEVSPACE" \
      "low" \
      "start,devspace_$DEVSPACE"
    
    # Get claude path from npm
    CLAUDE_PATH="$HOME/.npm-global/bin/claude"
    
    if [ ! -x "$CLAUDE_PATH" ]; then
      echo "❌ Claude not found at $CLAUDE_PATH"
      log "ERROR: Claude not found at $CLAUDE_PATH"
      exit 1
    fi
    
    # Set initial window name for tmux
    if [ -n "$TMUX" ]; then
      ${pkgs.tmux}/bin/tmux rename-window "claude" 2>/dev/null || true
    fi
    
    # Create a script to monitor output
    MONITOR_SCRIPT="/tmp/claude-monitor-$$.sh"
    cat > "$MONITOR_SCRIPT" << 'MONITOR_EOF'
#!/bin/bash
DEVSPACE="$1"
LOG_FILE="$2"
NFTY_TOPIC="$3"
NFTY_SERVER="$4"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] MONITOR: $1" >> "$LOG_FILE"
}

is_session_active() {
  if [ -n "$TMUX" ]; then
    local session_name=$(tmux display-message -p '#S' 2>/dev/null)
    
    # Check if any client is attached
    if ! tmux list-clients -t "$session_name" 2>/dev/null | grep -q .; then
      return 1
    fi
    
    # Check for recent activity
    local client_activity=$(tmux display-message -p '#{client_activity}' 2>/dev/null || echo "0")
    local current_time=$(date +%s)
    local idle_time=$((current_time - client_activity))
    
    # If idle for more than 120 seconds (2 minutes), consider inactive
    if [ $idle_time -gt 120 ]; then
      return 1
    fi
    
    return 0
  fi
  return 1
}

send_notification() {
  local title="$1"
  local message="$2"
  local priority="''${3:-default}"
  local tags="''${4:-}"
  
  if [ -z "${CLAUDE_FORCE_NOTIFY:-}" ] && is_session_active; then
    log "Notification suppressed (session active): $title"
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

last_activity=$(date +%s)
buffer=""
question_detected=false
completion_detected=false

while IFS= read -r line; do
  # Echo the line (preserving colors and escape sequences)
  printf '%s\n' "$line"
  
  # Log the line (stripping ANSI colors for readability)
  clean_line=$(printf '%s' "$line" | sed 's/\x1b\[[0-9;]*m//g')
  log "OUTPUT: $clean_line"
  
  # Update activity time
  last_activity=$(date +%s)
  
  # Check for terminal title escape sequences
  if [[ "$line" =~ $'\e]'[0-2]';'(.*)$'\a' ]]; then
    title="${BASH_REMATCH[1]}"
    if [ -n "$TMUX" ]; then
      tmux rename-window "$title" 2>/dev/null || true
    fi
  fi
  
  # Bell detection - check for actual bell character
  if printf '%s' "$line" | grep -q $'\a'; then
    log "Bell detected in line!"
    send_notification \
      "🔔 $DEVSPACE needs attention" \
      "Claude is requesting your input" \
      "high" \
      "bell,devspace_$DEVSPACE"
  fi
  
  # Check for questions (improved pattern)
  if [[ "$clean_line" =~ \?[[:space:]]*$ ]] || [[ "$clean_line" =~ ^[[:space:]]*[Dd]o[[:space:]]+you[[:space:]]+want ]]; then
    if [ "$question_detected" = false ]; then
      question_detected=true
      log "Question detected: $clean_line"
      send_notification \
        "❓ $DEVSPACE has a question" \
        "$clean_line" \
        "default" \
        "question,devspace_$DEVSPACE"
    fi
  else
    question_detected=false
  fi
  
  # Check for completion patterns
  if [[ "$clean_line" =~ (task[[:space:]]+completed|done|finished|complete[d]?)[[:punct:]]*$ ]] ||
     [[ "$clean_line" =~ ^[[:space:]]*(✓|✅|Done|Finished|Completed) ]]; then
    if [ "$completion_detected" = false ]; then
      completion_detected=true
      log "Completion detected: $clean_line"
      send_notification \
        "✅ $DEVSPACE task completed" \
        "$clean_line" \
        "default" \
        "done,devspace_$DEVSPACE"
    fi
  else
    completion_detected=false
  fi
  
  # Error detection
  if [[ "$clean_line" =~ (error|failed|failure|exception|traceback) ]]; then
    log "Error detected: $clean_line"
    send_notification \
      "🚨 $DEVSPACE encountered an error" \
      "$clean_line" \
      "high" \
      "error,devspace_$DEVSPACE"
  fi
done

# Check idle time periodically
(
  while true; do
    current_time=$(date +%s)
    idle_time=$((current_time - last_activity))
    
    if [ $idle_time -gt 300 ]; then
      log "Idle timeout detected ($idle_time seconds)"
      send_notification \
        "💤 $DEVSPACE is idle" \
        "No output for $((idle_time / 60)) minutes" \
        "low" \
        "idle,devspace_$DEVSPACE"
      break
    fi
    
    sleep 60
  done
) &
MONITOR_EOF

    chmod +x "$MONITOR_SCRIPT"
    
    # Use script command to capture ALL output including bells and escape sequences
    # The -e flag returns the exit code of the child process
    # The -q flag suppresses script's own output
    # The -c flag specifies the command to run
    ${pkgs.util-linux}/bin/script -e -q -c "
      '$CLAUDE_PATH' $* 2>&1 | '$MONITOR_SCRIPT' '$DEVSPACE' '$LOG_FILE' '$NFTY_TOPIC' '$NFTY_SERVER'
    " /dev/null
    
    CLAUDE_EXIT=$?
    
    # Clean up
    rm -f "$MONITOR_SCRIPT"
    
    # Send final notification
    if [ $CLAUDE_EXIT -eq 0 ]; then
      send_notification \
        "👋 $DEVSPACE Claude stopped" \
        "Claude Code exited normally" \
        "low" \
        "stop,devspace_$DEVSPACE"
    else
      send_notification \
        "💥 $DEVSPACE Claude crashed" \
        "Claude Code exited with code $CLAUDE_EXIT" \
        "urgent" \
        "crash,devspace_$DEVSPACE"
    fi
    
    log "Claude Code wrapper terminated with exit code $CLAUDE_EXIT"
    exit $CLAUDE_EXIT
  '';
  
  claudeDevspaceScript = pkgs.writeScriptBin "claude-devspace" ''
    #!${pkgs.bash}/bin/bash
    # 🪐 Start Claude in the current directory with devspace notifications
    
    DEVSPACE="''${TMUX_DEVSPACE:-}"
    
    if [ -z "$DEVSPACE" ]; then
      echo "❌ Not in a devspace tmux session!"
      echo "Use one of: mercury, venus, earth, mars, jupiter"
      exit 1
    fi
    
    echo "📁 Starting Claude in $(pwd)"
    
    # Start Claude with notifications
    exec claude-notify "$@"
  '';
  
  # 🤖 Smart Claude wrapper that works everywhere
  claudeSmartWrapper = pkgs.writeScriptBin "claude" ''
    #!${pkgs.bash}/bin/bash
    # 🤖 Smart Claude wrapper - uses notifications in devspaces, regular claude otherwise
    
    if [ -n "''${TMUX_DEVSPACE:-}" ]; then
      # In a devspace - use notification wrapper
      exec claude-notify "$@"
    else
      # Not in a devspace - use regular claude from npm
      exec "$HOME/.npm-global/bin/claude" "$@"
    fi
  '';

in {
  options.programs.claude-wrapper = {
    enable = mkEnableOption "Claude Code wrapper with notifications";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      claudeNotifyScript
      claudeDevspaceScript
      claudeSmartWrapper
      util-linux  # for script command
    ];

    # Shell aliases
    programs.zsh.shellAliases = {
      cn = "claude-notify";
      cld = "claude-devspace";  # Explicit devspace claude
    };
  };
}