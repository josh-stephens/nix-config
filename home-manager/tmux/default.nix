{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.tmux-devspace;

  # 🪐 Import devspace theme configuration
  theme = import ../../pkgs/devspaces/theme.nix; # Assuming this path is correct relative to this file
  devspaceConfig = {
    devspaces = map (s: {
      name = s.name;
      color = s.color; # Used for devspace-specific active pane border
      description = "${s.icon} ${s.name} - ${s.description}";
      hotkey = s.hotkey;
    }) theme.spaces;
  };

  # Fetch erikw/tmux-powerline
  tmuxPowerlinePackage = pkgs.fetchFromGitHub {
    owner = "erikw";
    repo = "tmux-powerline";
    rev = "ad98fe32b1c96ebe4872bbb9e20ceeb0fd9b24ad";
    sha256 = "sha256-WGLNjvvBBmS9dIHV08QJuiEBjv+6uubKlTnMITBdnXo="; # IMPORTANT: Replace with actual SHA256 hash
  };

  # Fetch kjnsn/catppuccin-tmux-powerline theme
  tmuxPowerlineCatppuccinThemePackage = pkgs.fetchFromGitHub {
    owner = "kjnsn";
    repo = "catppuccin-tmux-powerline";
    rev = "015ae53948495ad18897c15fdad7ba6445d3709f"; # Latest commit as of checking
    sha256 = lib.fakeSha256; # IMPORTANT: Replace with actual SHA256 hash
  };

  # 🚀 Devspace management scripts
  devspaceInitScript = pkgs.writeScriptBin "devspace-init" ''
    #!${pkgs.bash}/bin/bash
    # 🚀 Initialize all devspace tmux sessions
    
    set -euo pipefail
    
    DEVSPACES=(${concatStringsSep " " (map (p: ''"${p.name}"'') devspaceConfig.devspaces)})
    COLORS=(${concatStringsSep " " (map (p: ''"${p.color}"'') devspaceConfig.devspaces)})
    
    echo "🌌 Initializing devspace development environments..."
    
    for i in "''${!DEVSPACES[@]}"; do
      devspace="''${DEVSPACES[$i]}"
      color="''${COLORS[$i]}"
      session="devspace-$devspace"
      
      if ! ${pkgs.tmux}/bin/tmux has-session -t "$session" 2>/dev/null; then
        echo "🪐 Creating $devspace (color: $color)..."
        
        # Create session with environment variables
        TMUX_DEVSPACE="$devspace" TMUX_DEVSPACE_COLOR="$color" ${pkgs.tmux}/bin/tmux new-session -d -s "$session" -n claude
        
        # Set environment for the session
        ${pkgs.tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE "$devspace"
        ${pkgs.tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE_COLOR "$color"
        
        # Create default windows
        ${pkgs.tmux}/bin/tmux new-window -t "$session:2" -n nvim
        ${pkgs.tmux}/bin/tmux new-window -t "$session:3" -n term
        ${pkgs.tmux}/bin/tmux new-window -t "$session:4" -n logs
        
        # Set working directory if it exists
        if [ -d "$HOME/devspaces/$devspace" ]; then
          ${pkgs.tmux}/bin/tmux send-keys -t "$session:1" "cd ~/devspaces/$devspace" Enter
          ${pkgs.tmux}/bin/tmux send-keys -t "$session:2" "cd ~/devspaces/$devspace" Enter
          ${pkgs.tmux}/bin/tmux send-keys -t "$session:3" "cd ~/devspaces/$devspace" Enter
        fi
        
        # Start log monitoring in window 4
        ${pkgs.tmux}/bin/tmux send-keys -t "$session:4" "tail -f ~/.claude-code-$devspace.log 2>/dev/null || echo '📋 Log file will appear when Claude starts...'" Enter
      else
        echo "✅ $devspace already exists"
      fi
    done
    
    echo "✨ All devspaces initialized!"
    ${pkgs.tmux}/bin/tmux list-sessions
  '';
  
  devspaceStatusScript = pkgs.writeScriptBin "devspace-status" ''
    #!${pkgs.bash}/bin/bash
    # 📊 Show status of all devspace sessions
    
    echo "🌌 Devspace Development Environment Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    
    DEVSPACES=(${concatStringsSep " " (map (p: ''"${p.name}"'') devspaceConfig.devspaces)})
    DESCRIPTIONS=(
      ${concatStringsSep "\n      " (map (p: ''"${p.description}"'') devspaceConfig.devspaces)}
    )
    
    for i in "''${!DEVSPACES[@]}"; do
      devspace="''${DEVSPACES[$i]}"
      desc="''${DESCRIPTIONS[$i]}"
      session="devspace-$devspace"
      
      echo "$desc"
      
      if ${pkgs.tmux}/bin/tmux has-session -t "$session" 2>/dev/null; then
        # Get current window
        current_window=$(${pkgs.tmux}/bin/tmux display-message -t "$session" -p '#W' 2>/dev/null || echo "unknown")
        
        # Check for linked project
        if [ -L "$HOME/devspaces/$devspace/project" ]; then
          project=$(readlink "$HOME/devspaces/$devspace/project" | xargs basename)
          echo "  📁 Project: $project"
        else
          echo "  📁 Project: none"
        fi
        
        echo "  🪟 Current window: $current_window"
        echo "  ✅ Status: active"
      else
        echo "  ❌ Status: not initialized"
      fi
      echo
    done
  '';
  
  # 🔗 Remote link opening script for server side
  remoteLinkOpenScript = pkgs.writeScriptBin "remote-link-open" ''
    #!${pkgs.bash}/bin/bash
    # 🔗 Open links on the client machine when running on a remote server
    
    set -euo pipefail
    
    if [ $# -eq 0 ]; then
      echo "Usage: remote-link-open <url>"
      exit 1
    fi
    
    URL="$1"
    
    # Check if we're in an SSH session
    if [ -z "''${SSH_CLIENT:-}" ]; then
      echo "Not in an SSH session, opening locally..."
      if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$URL"
      elif command -v open >/dev/null 2>&1; then
        open "$URL"
      else
        echo "No suitable browser opener found"
        exit 1
      fi
      exit 0
    fi
    
    # Get the client IP
    CLIENT_IP=$(echo $SSH_CLIENT | awk '{print $1}')
    
    # Use OSC 8 hyperlink sequence that kitty will intercept
    printf '\033]8;;%s\033\\Click to open: %s\033]8;;\033\\\n' "$URL" "$URL"
    
    # Also try to send via kitty remote control if available
    if [ -n "''${KITTY_WINDOW_ID:-}" ]; then
      # Send a notification to kitty that can be intercepted
      printf '\033]99;open-url:%s\033\\' "$URL"
    fi
    
    # Log for debugging
    echo "[$(date)] Remote link open request: $URL from $CLIENT_IP" >> ~/.remote-link-open.log
  '';
  
  # 🤖 Claude notification wrapper scripts
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
    
    # 📨 Send notification
    send_notification() {
      local title="$1"
      local message="$2"
      local priority="''${3:-default}"
      local tags="''${4:-}"
      
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
    
    # Run claude with all arguments passed through
    ${pkgs.claude-code}/bin/claude "$@" > "$STDOUT_FIFO" 2> "$STDERR_FIFO" &
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
    # 🪐 Start Claude in the current devspace's project directory
    
    DEVSPACE="''${TMUX_DEVSPACE:-}"
    
    if [ -z "$DEVSPACE" ]; then
      echo "❌ Not in a devspace tmux session!"
      echo "Use one of: mercury, venus, earth, mars, jupiter"
      exit 1
    fi
    
    # Check for linked project
    if [ -L "$HOME/devspaces/$DEVSPACE/project" ]; then
      cd "$HOME/devspaces/$DEVSPACE/project"
      echo "📁 Starting Claude in $(pwd)"
    else
      echo "⚠️  No project linked to $DEVSPACE"
      echo "Use: devspace-setup $DEVSPACE /path/to/project"
      exit 1
    fi
    
    # Start Claude with notifications
    exec claude-notify "$@"
  '';
  
  devspaceSetupScript = pkgs.writeScriptBin "devspace-setup" ''
    #!${pkgs.bash}/bin/bash
    # 🔧 Set up or change a devspace's project
    
    set -euo pipefail
    
    if [ $# -lt 1 ]; then
      echo "Usage: devspace-setup <devspace> [project-path]"
      echo "  devspace-setup earth ~/projects/work/main-app"
      echo "  devspace-setup mars ."
      exit 1
    fi
    
    DEVSPACE="$1"
    PROJECT_PATH="''${2:-}"
    
    # Validate devspace name
    if [[ ! "$DEVSPACE" =~ ^(mercury|venus|earth|mars|jupiter)$ ]]; then
      echo "❌ Invalid devspace: $DEVSPACE"
      echo "Valid devspaces: mercury, venus, earth, mars, jupiter"
      exit 1
    fi
    
    DEVSPACE_DIR="$HOME/devspaces/$DEVSPACE"
    
    # Create devspace directory if needed
    mkdir -p "$DEVSPACE_DIR"
    
    # If no project path specified, show current setup
    if [ -z "$PROJECT_PATH" ]; then
      echo "🪐 Current setup for $DEVSPACE:"
      if [ -L "$DEVSPACE_DIR/project" ]; then
        echo "  📁 Project: $(readlink "$DEVSPACE_DIR/project")"
      else
        echo "  📁 No project linked"
      fi
      exit 0
    fi
    
    # Resolve project path
    if [ "$PROJECT_PATH" = "." ]; then
      PROJECT_PATH=$(pwd)
    else
      PROJECT_PATH=$(realpath "$PROJECT_PATH")
    fi
    
    # Validate project path
    if [ ! -d "$PROJECT_PATH" ]; then
      echo "❌ Project path does not exist: $PROJECT_PATH"
      exit 1
    fi
    
    # Check if already linked
    if [ -L "$DEVSPACE_DIR/project" ]; then
      current=$(readlink "$DEVSPACE_DIR/project")
      if [ "$current" = "$PROJECT_PATH" ]; then
        echo "✅ $DEVSPACE is already linked to $PROJECT_PATH"
        exit 0
      fi
      
      echo "⚠️  $DEVSPACE is currently linked to: $current"
      read -p "Replace with $PROJECT_PATH? (y/N) " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Cancelled"
        exit 1
      fi
      
      rm "$DEVSPACE_DIR/project"
    fi
    
    # Create symlink
    ln -s "$PROJECT_PATH" "$DEVSPACE_DIR/project"
    echo "✅ Linked $DEVSPACE to $PROJECT_PATH"
    
    # Update tmux session if it exists
    session="devspace-$DEVSPACE"
    if ${pkgs.tmux}/bin/tmux has-session -t "$session" 2>/dev/null; then
      # Send cd command to all windows
      for window in 1 2 3; do
        ${pkgs.tmux}/bin/tmux send-keys -t "$session:$window" C-c "cd $PROJECT_PATH" Enter
      done
      echo "📍 Updated working directory in tmux session"
    fi
  '';

in {
  options.programs.tmux-devspace = {
    enable = mkEnableOption "tmux devspace development environment";

    devspaceMode = mkOption {
      type = types.bool;
      default = false;
      description = "Enable devspace development environment mode";
    };

    remoteOpener = mkOption {
      type = types.bool;
      default = false;
      description = "Enable remote link opening (server-side)";
    };

    claudeNotifications = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Claude Code notification wrapper";
    };

    enableSystemdService = mkOption {
      type = types.bool;
      default = false;
      description = "Enable systemd service to initialize devspaces on boot (NixOS only)";
    };
  };

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      clock24 = true;
      escapeTime = 0;
      historyLimit = 50000;
      keyMode = "vi";
      terminal = "tmux-256color"; # Ensure your terminal supports 256 colors
      mouse = true;
      baseIndex = 1; # Windows start at 1

      extraConfig = ''
        # 🔧 General Tmux Settings
        setw -g pane-base-index 1
        set -g renumber-windows on     # Renumber windows when one is closed
        set -g set-titles on           # Set terminal titles
        set -g focus-events on         # For better editor integration (e.g., Neovim)
        set -g status-position bottom  # Display status bar at the bottom

        # 🎨 tmux-powerline (erikw/tmux-powerline) Configuration
        # These settings must be defined/sourced BEFORE sourcing powerline.sh

        # 1. Source the Catppuccin Mocha theme for tmux-powerline.
        #    This theme file sets global @catppuccin_mocha_* color variables
        #    and @powerline_color_* variables for tmux-powerline segments.
        source "${tmuxPowerlineCatppuccinThemePackage}/themes/catppuccin_mocha.tmux"

        # 2. Configure segments: only "windows" (tabs) on the left, nothing on the right.
        set -g @powerline_segments_left "windows"
        set -g @powerline_segments_right ""

        # 3. Configure window segment format to show only window name with padding.
        #    This overrides any default format (like icons/indices) set by the theme.
        set -g @powerline_window_status_current_format " #W " # Padded window name for current window
        set -g @powerline_window_status_format " #W "       # Padded window name for other windows

        # 🎯 Pane borders (uses global @catppuccin_mocha_* vars set by the sourced theme)
        set -g pane-border-style "fg=#{@catppuccin_mocha_surface0}"
        ${if cfg.devspaceMode then ''
          set -g pane-active-border-style "fg=#{@catppuccin_mocha_#{TMUX_DEVSPACE_COLOR}}"
        '' else ''
          set -g pane-active-border-style "fg=#{@catppuccin_mocha_blue}"
        ''}

        # 🌍 Update environment to include devspace variables
        set -ga update-environment " TMUX_DEVSPACE TMUX_DEVSPACE_COLOR TMUX_DEVSPACE_ICON TMUX_DEVSPACE_INITIALIZED"

        # 🔔 Bell settings for notifications
        set -g bell-action any
        set -g visual-bell off
        set -g visual-activity off
        setw -g monitor-activity on # tmux-powerline uses this for activity indicators

        # 📋 Terminal integration
        set -g allow-passthrough on # Allow OSC52 sequences for clipboard

        ${optionalString cfg.devspaceMode ''
          # 🪝 Devspace state saving hooks (if devspaceMode is enabled)
          set-hook -g window-linked 'if -F "#{m:devspace-*,#{session_name}}" "run-shell -b \"devspace-save-hook 2>/dev/null || true\""'
          set-hook -g window-unlinked 'if -F "#{m:devspace-*,#{session_name}}" "run-shell -b \"devspace-save-hook 2>/dev/null || true\""'
          set-hook -g client-detached 'run-shell -b "devspace-save-hook 2>/dev/null || true"'
          set-hook -g session-created 'if -F "#{m:devspace-*,#{session_name}}" "run-shell -b \"devspace-save-hook 2>/dev/null || true\""'
        ''}

        # ⌨️ Key bindings (Copied from your original config)
        # 📋 Better copy mode
        bind-key v copy-mode
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

        # 🔄 Reload config
        bind-key r source-file ~/.tmux.conf \; display-message "⚡ Config reloaded!"

        # 🚪 Better pane management
        bind-key | split-window -h -c "#{pane_current_path}"
        bind-key - split-window -v -c "#{pane_current_path}"
        bind-key x kill-pane
        bind-key X kill-window

        # 📍 Navigate panes with vim keys
        bind-key h select-pane -L
        bind-key j select-pane -D
        bind-key k select-pane -U
        bind-key l select-pane -R

        ${optionalString cfg.devspaceMode ''
          # ⌨️ Devspace-specific keybindings
          # Quick window switching with memorable keys
          bind-key c select-window -t :1  # Claude
          bind-key n select-window -t :2  # Neovim
          bind-key t select-window -t :3  # Terminal
          bind-key l select-window -t :4  # Logs

          # 🚀 Quick session switching (theme-based hotkeys)
          ${concatStringsSep "\n          " (map (d:
            "bind-key -n M-${d.hotkey} switch-client -t devspace-${d.name}"
          ) devspaceConfig.devspaces)}
        ''}

        # 4. Source tmux-powerline's main script to generate the status bar.
        #    This MUST be one of the last lines related to tmux-powerline.
        source "${tmuxPowerlinePackage}/powerline.sh"
        # End of tmux-powerline Configuration
      ''; # End of extraConfig
    }; # End of programs.tmux

    home.packages = with pkgs; (optionals cfg.devspaceMode [
      devspaceInitScript
      devspaceStatusScript
      devspaceSetupScript
    ]) ++ (optionals cfg.remoteOpener [
      remoteLinkOpenScript
    ]) ++ (optionals (cfg.devspaceMode && cfg.claudeNotifications) [
      claudeNotifyScript
      claudeDevspaceScript
    ]);

    # 📁 Create devspace directories if devspace mode is enabled
    home.file = mkIf cfg.devspaceMode (
      listToAttrs (map (devspace: {
        name = "devspaces/${devspace.name}/.keep";
        value = {
          text = "";
        };
      }) devspaceConfig.devspaces)
    );

    # 🌐 Set up environment for remote link opening
    home.sessionVariables = mkIf cfg.remoteOpener {
      BROWSER = "remote-link-open";
      DEFAULT_BROWSER = "remote-link-open";
    };

    # 🔧 Shell aliases for Claude commands
    programs.zsh.shellAliases = mkIf (cfg.devspaceMode && cfg.claudeNotifications) {
      claude = "claude-devspace";
      cn = "claude-notify";
    };
  }; # End of config = mkIf cfg.enable
} # End of file
