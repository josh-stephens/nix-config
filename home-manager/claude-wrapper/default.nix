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
    
    # 🔍 Check if session is attached
    is_session_attached() {
      if [ -n "$TMUX" ]; then
        # Get session name from TMUX environment
        local session_name=$(${pkgs.tmux}/bin/tmux display-message -p '#S' 2>/dev/null)
        # Check if any client is attached to this session
        ${pkgs.tmux}/bin/tmux list-clients -t "$session_name" 2>/dev/null | grep -q . && return 0
      fi
      return 1
    }
    
    # 📨 Send notification
    send_notification() {
      local title="$1"
      local message="$2"
      local priority="''${3:-default}"
      local tags="''${4:-}"
      
      # Skip notifications if session is attached (user is actively present)
      # unless CLAUDE_FORCE_NOTIFY is set
      if [ -z "''${CLAUDE_FORCE_NOTIFY:-}" ] && is_session_attached; then
        log "Notification suppressed (session attached): $title"
        return
      fi
      
      ${pkgs.curl}/bin/curl -s \
        -H "Title: $title" \
        -H "Priority: $priority" \
        -H "Tags: $tags" \
        -d "$message" \
        "$NFTY_SERVER/$NFTY_TOPIC" > /dev/null || true
    }
    
    # 🚀 Start Claude Code
    echo -e "''${BLUE}🤖 Starting Claude Code in devspace $DEVSPACE...''${NC}"
    log "Starting Claude Code wrapper"
    
    # Create temporary files for output monitoring
    STDOUT_FIFO="/tmp/claude-$DEVSPACE-$$.out"
    STDERR_FIFO="/tmp/claude-$DEVSPACE-$$.err"
    mkfifo "$STDOUT_FIFO" "$STDERR_FIFO"
    
    # Cleanup on exit
    cleanup() {
      rm -f "$STDOUT_FIFO" "$STDERR_FIFO"
      log "Claude Code wrapper terminated"
    }
    trap cleanup EXIT
    
    # 🔍 Monitor function
    monitor_output() {
      local last_output_time=$(date +%s)
      local idle_threshold=300  # 5 minutes
      local buffer=""
      local question_detected=false
      local completion_detected=false
      
      while IFS= read -r line; do
        # Echo to terminal
        echo "$line"
        
        # Add to buffer for context
        buffer="$buffer
    $line"
        
        # Keep buffer reasonable size (last 10 lines)
        buffer=$(echo "$buffer" | tail -n 10)
        
        # Log output
        log "OUTPUT: $line"
        
        # Update last output time
        last_output_time=$(date +%s)
        
        # 🔔 Check for bell character
        if [[ "$line" == *$'\a'* ]]; then
          log "Bell detected!"
          send_notification \
            "🔔 $DEVSPACE needs attention" \
            "Claude is requesting your input" \
            "high" \
            "bell,devspace_$DEVSPACE"
        fi
        
        # ❓ Check for questions
        if [[ "$line" =~ \?[[:space:]]*$ ]]; then
          if [ "$question_detected" = false ]; then
            question_detected=true
            log "Question detected: $line"
            send_notification \
              "❓ $DEVSPACE has a question" \
              "$line" \
              "default" \
              "question,devspace_$DEVSPACE"
          fi
        else
          question_detected=false
        fi
        
        # ✅ Check for completion patterns
        if [[ "$line" =~ (task[[:space:]]+completed|done|finished|complete[d]?)[[:punct:]]*$ ]] ||
           [[ "$line" =~ ^[[:space:]]*(✓|✅|Done|Finished|Completed) ]]; then
          if [ "$completion_detected" = false ]; then
            completion_detected=true
            log "Completion detected: $line"
            send_notification \
              "✅ $DEVSPACE task completed" \
              "$line" \
              "default" \
              "done,devspace_$DEVSPACE"
          fi
        else
          completion_detected=false
        fi
        
        # 🚨 Check for errors
        if [[ "$line" =~ (error|failed|failure|exception|traceback) ]]; then
          log "Error detected: $line"
          send_notification \
            "🚨 $DEVSPACE encountered an error" \
            "$line" \
            "high" \
            "error,devspace_$DEVSPACE"
        fi
      done < "$1"
      
      # Check for idle timeout in background
      (
        while true; do
          current_time=$(date +%s)
          idle_time=$((current_time - last_output_time))
          
          if [ $idle_time -gt $idle_threshold ]; then
            log "Idle timeout detected ($idle_time seconds)"
            send_notification \
              "💤 $DEVSPACE is idle" \
              "No output for $(($idle_time / 60)) minutes" \
              "low" \
              "idle,devspace_$DEVSPACE"
            break
          fi
          
          sleep 60
        done
      ) &
    }
    
    # 📊 Start monitoring in background
    monitor_output "$STDOUT_FIFO" &
    MONITOR_PID=$!
    
    # 🎬 Run Claude Code with output redirection
    echo -e "''${GREEN}✨ Claude Code starting...''${NC}"
    send_notification \
      "🚀 $DEVSPACE Claude starting" \
      "Claude Code is initializing in devspace $DEVSPACE" \
      "low" \
      "start,devspace_$DEVSPACE"
    
    # Get claude path from npm
    CLAUDE_PATH="$HOME/.npm-global/bin/claude"
    
    # Run claude with all arguments passed through
    "$CLAUDE_PATH" "$@" > "$STDOUT_FIFO" 2> "$STDERR_FIFO" &
    CLAUDE_PID=$!
    
    # Monitor stderr separately
    while IFS= read -r line; do
      echo "$line" >&2
      log "STDERR: $line"
    done < "$STDERR_FIFO" &
    
    # Wait for Claude to finish
    wait $CLAUDE_PID
    CLAUDE_EXIT=$?
    
    # Clean up monitor
    kill $MONITOR_PID 2>/dev/null || true
    
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
    ];

    # Shell aliases
    programs.zsh.shellAliases = {
      cn = "claude-notify";
      cld = "claude-devspace";  # Explicit devspace claude
    };
  };
}