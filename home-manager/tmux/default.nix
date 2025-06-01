{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.tmux-planet;
  
  # 🪐 Planet configuration
  planetConfig = {
    planets = [
      { name = "mercury"; color = "flamingo"; description = "☿ Mercury - Quick experiments"; }
      { name = "venus"; color = "pink"; description = "♀ Venus - Personal creative projects"; }
      { name = "earth"; color = "green"; description = "🌍 Earth - Primary work"; }
      { name = "mars"; color = "red"; description = "♂ Mars - Secondary work"; }
      { name = "jupiter"; color = "peach"; description = "♃ Jupiter - Large personal project"; }
    ];
  };
  
  # 🎨 Catppuccin Mocha theme colors
  catppuccinColors = ''
    # 🎨 Catppuccin Mocha Color Palette
    set -g @catppuccin_mocha_rosewater "#f5e0dc"
    set -g @catppuccin_mocha_flamingo "#f2cdcd"
    set -g @catppuccin_mocha_pink "#f5c2e7"
    set -g @catppuccin_mocha_mauve "#cba6f7"
    set -g @catppuccin_mocha_red "#f38ba8"
    set -g @catppuccin_mocha_maroon "#eba0ac"
    set -g @catppuccin_mocha_peach "#fab387"
    set -g @catppuccin_mocha_yellow "#f9e2af"
    set -g @catppuccin_mocha_green "#a6e3a1"
    set -g @catppuccin_mocha_teal "#94e2d5"
    set -g @catppuccin_mocha_sky "#89dceb"
    set -g @catppuccin_mocha_sapphire "#74c7ec"
    set -g @catppuccin_mocha_blue "#89b4fa"
    set -g @catppuccin_mocha_lavender "#b4befe"
    set -g @catppuccin_mocha_text "#cdd6f4"
    set -g @catppuccin_mocha_base "#1e1e2e"
    set -g @catppuccin_mocha_mantle "#181825"
    set -g @catppuccin_mocha_crust "#11111b"
  '';
  
  # 🚀 Planet management scripts
  planetInitScript = pkgs.writeScriptBin "planet-init" ''
    #!${pkgs.bash}/bin/bash
    # 🚀 Initialize all planet tmux sessions
    
    set -euo pipefail
    
    PLANETS=(${concatStringsSep " " (map (p: ''"${p.name}"'') planetConfig.planets)})
    COLORS=(${concatStringsSep " " (map (p: ''"${p.color}"'') planetConfig.planets)})
    
    echo "🌌 Initializing planet development environments..."
    
    for i in "''${!PLANETS[@]}"; do
      planet="''${PLANETS[$i]}"
      color="''${COLORS[$i]}"
      session="planet-$planet"
      
      if ! ${pkgs.tmux}/bin/tmux has-session -t "$session" 2>/dev/null; then
        echo "🪐 Creating $planet (color: $color)..."
        
        # Create session with environment variables
        TMUX_PLANET="$planet" TMUX_PLANET_COLOR="$color" ${pkgs.tmux}/bin/tmux new-session -d -s "$session" -n claude
        
        # Set environment for the session
        ${pkgs.tmux}/bin/tmux set-environment -t "$session" TMUX_PLANET "$planet"
        ${pkgs.tmux}/bin/tmux set-environment -t "$session" TMUX_PLANET_COLOR "$color"
        
        # Create default windows
        ${pkgs.tmux}/bin/tmux new-window -t "$session:2" -n nvim
        ${pkgs.tmux}/bin/tmux new-window -t "$session:3" -n term
        ${pkgs.tmux}/bin/tmux new-window -t "$session:4" -n logs
        
        # Set working directory if it exists
        if [ -d "$HOME/planets/$planet" ]; then
          ${pkgs.tmux}/bin/tmux send-keys -t "$session:1" "cd ~/planets/$planet" Enter
          ${pkgs.tmux}/bin/tmux send-keys -t "$session:2" "cd ~/planets/$planet" Enter
          ${pkgs.tmux}/bin/tmux send-keys -t "$session:3" "cd ~/planets/$planet" Enter
        fi
        
        # Start log monitoring in window 4
        ${pkgs.tmux}/bin/tmux send-keys -t "$session:4" "tail -f ~/.claude-code-$planet.log 2>/dev/null || echo '📋 Log file will appear when Claude starts...'" Enter
      else
        echo "✅ $planet already exists"
      fi
    done
    
    echo "✨ All planets initialized!"
    ${pkgs.tmux}/bin/tmux list-sessions
  '';
  
  planetStatusScript = pkgs.writeScriptBin "planet-status" ''
    #!${pkgs.bash}/bin/bash
    # 📊 Show status of all planet sessions
    
    echo "🌌 Planet Development Environment Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    
    PLANETS=(${concatStringsSep " " (map (p: ''"${p.name}"'') planetConfig.planets)})
    DESCRIPTIONS=(
      ${concatStringsSep "\n      " (map (p: ''"${p.description}"'') planetConfig.planets)}
    )
    
    for i in "''${!PLANETS[@]}"; do
      planet="''${PLANETS[$i]}"
      desc="''${DESCRIPTIONS[$i]}"
      session="planet-$planet"
      
      echo "$desc"
      
      if ${pkgs.tmux}/bin/tmux has-session -t "$session" 2>/dev/null; then
        # Get current window
        current_window=$(${pkgs.tmux}/bin/tmux display-message -t "$session" -p '#W' 2>/dev/null || echo "unknown")
        
        # Check for linked project
        if [ -L "$HOME/planets/$planet/project" ]; then
          project=$(readlink "$HOME/planets/$planet/project" | xargs basename)
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
    PLANET="''${TMUX_PLANET:-unknown}"
    LOG_FILE="$HOME/.claude-code-$PLANET.log"
    
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
    echo -e "''${BLUE}🤖 Starting Claude Code on planet $PLANET...''${NC}"
    log "Starting Claude Code wrapper"
    
    # Create temporary files for output monitoring
    STDOUT_FIFO="/tmp/claude-$PLANET-$$.out"
    STDERR_FIFO="/tmp/claude-$PLANET-$$.err"
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
            "🔔 $PLANET needs attention" \
            "Claude is requesting your input" \
            "high" \
            "bell,planet_$PLANET"
        fi
        
        # ❓ Check for questions
        if [[ "$line" =~ \?[[:space:]]*$ ]]; then
          if [ "$question_detected" = false ]; then
            question_detected=true
            log "Question detected: $line"
            send_notification \
              "❓ $PLANET has a question" \
              "$line" \
              "default" \
              "question,planet_$PLANET"
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
              "✅ $PLANET task completed" \
              "$line" \
              "default" \
              "done,planet_$PLANET"
          fi
        else
          completion_detected=false
        fi
        
        # 🚨 Check for errors
        if [[ "$line" =~ (error|failed|failure|exception|traceback) ]]; then
          log "Error detected: $line"
          send_notification \
            "🚨 $PLANET encountered an error" \
            "$line" \
            "high" \
            "error,planet_$PLANET"
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
              "💤 $PLANET is idle" \
              "No output for $(($idle_time / 60)) minutes" \
              "low" \
              "idle,planet_$PLANET"
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
      "🚀 $PLANET Claude starting" \
      "Claude Code is initializing on planet $PLANET" \
      "low" \
      "start,planet_$PLANET"
    
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
        "👋 $PLANET Claude stopped" \
        "Claude Code exited normally" \
        "low" \
        "stop,planet_$PLANET"
    else
      send_notification \
        "💥 $PLANET Claude crashed" \
        "Claude Code exited with code $CLAUDE_EXIT" \
        "urgent" \
        "crash,planet_$PLANET"
    fi
    
    exit $CLAUDE_EXIT
  '';
  
  claudePlanetScript = pkgs.writeScriptBin "claude-planet" ''
    #!${pkgs.bash}/bin/bash
    # 🪐 Start Claude in the current planet's project directory
    
    PLANET="''${TMUX_PLANET:-}"
    
    if [ -z "$PLANET" ]; then
      echo "❌ Not in a planet tmux session!"
      echo "Use one of: mercury, venus, earth, mars, jupiter"
      exit 1
    fi
    
    # Check for linked project
    if [ -L "$HOME/planets/$PLANET/project" ]; then
      cd "$HOME/planets/$PLANET/project"
      echo "📁 Starting Claude in $(pwd)"
    else
      echo "⚠️  No project linked to $PLANET"
      echo "Use: planet-setup $PLANET /path/to/project"
      exit 1
    fi
    
    # Start Claude with notifications
    exec claude-notify "$@"
  '';
  
  planetSetupScript = pkgs.writeScriptBin "planet-setup" ''
    #!${pkgs.bash}/bin/bash
    # 🔧 Set up or change a planet's project
    
    set -euo pipefail
    
    if [ $# -lt 1 ]; then
      echo "Usage: planet-setup <planet> [project-path]"
      echo "  planet-setup earth ~/projects/work/main-app"
      echo "  planet-setup mars ."
      exit 1
    fi
    
    PLANET="$1"
    PROJECT_PATH="''${2:-}"
    
    # Validate planet name
    if [[ ! "$PLANET" =~ ^(mercury|venus|earth|mars|jupiter)$ ]]; then
      echo "❌ Invalid planet: $PLANET"
      echo "Valid planets: mercury, venus, earth, mars, jupiter"
      exit 1
    fi
    
    PLANET_DIR="$HOME/planets/$PLANET"
    
    # Create planet directory if needed
    mkdir -p "$PLANET_DIR"
    
    # If no project path specified, show current setup
    if [ -z "$PROJECT_PATH" ]; then
      echo "🪐 Current setup for $PLANET:"
      if [ -L "$PLANET_DIR/project" ]; then
        echo "  📁 Project: $(readlink "$PLANET_DIR/project")"
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
    if [ -L "$PLANET_DIR/project" ]; then
      current=$(readlink "$PLANET_DIR/project")
      if [ "$current" = "$PROJECT_PATH" ]; then
        echo "✅ $PLANET is already linked to $PROJECT_PATH"
        exit 0
      fi
      
      echo "⚠️  $PLANET is currently linked to: $current"
      read -p "Replace with $PROJECT_PATH? (y/N) " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Cancelled"
        exit 1
      fi
      
      rm "$PLANET_DIR/project"
    fi
    
    # Create symlink
    ln -s "$PROJECT_PATH" "$PLANET_DIR/project"
    echo "✅ Linked $PLANET to $PROJECT_PATH"
    
    # Update tmux session if it exists
    session="planet-$PLANET"
    if ${pkgs.tmux}/bin/tmux has-session -t "$session" 2>/dev/null; then
      # Send cd command to all windows
      for window in 1 2 3; do
        ${pkgs.tmux}/bin/tmux send-keys -t "$session:$window" C-c "cd $PROJECT_PATH" Enter
      done
      echo "📍 Updated working directory in tmux session"
    fi
  '';

in {
  options.programs.tmux-planet = {
    enable = mkEnableOption "tmux planet development environment";
    
    planetMode = mkOption {
      type = types.bool;
      default = false;
      description = "Enable planet development environment mode";
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
      description = "Enable systemd service to initialize planets on boot (NixOS only)";
    };
  };

  config = mkIf cfg.enable {
    # Enable the base tmux module
    programs.tmux = {
      enable = true;
      clock24 = true;
      escapeTime = 0;
      historyLimit = 50000;
      keyMode = "vi";
      terminal = "tmux-256color";
      mouse = true;
      baseIndex = 1;
      
      extraConfig = ''
        ${catppuccinColors}
        
        # 🔧 General Settings
        setw -g pane-base-index 1
        set -g renumber-windows on
        set -g set-titles on
        set -g focus-events on
        
        # 🔔 Bell settings for notifications
        set -g bell-action any
        set -g visual-bell off
        set -g visual-activity off
        setw -g monitor-activity on
        
        # 🎨 Status Bar Styling
        set -g status-style "fg=#{@catppuccin_mocha_text},bg=#{@catppuccin_mocha_base}"
        set -g status-left-length 50
        set -g status-right-length 100
        
        ${if cfg.planetMode then ''
          # 🪐 Dynamic planet coloring based on session name
          set -g status-left "#[fg=#{@catppuccin_mocha_base},bg=#{@catppuccin_mocha_#{TMUX_PLANET_COLOR}},bold] 🪐 #S #[fg=#{@catppuccin_mocha_#{TMUX_PLANET_COLOR}},bg=#{@catppuccin_mocha_base}]"
        '' else ''
          set -g status-left "#[fg=#{@catppuccin_mocha_base},bg=#{@catppuccin_mocha_blue},bold] #S #[fg=#{@catppuccin_mocha_blue},bg=#{@catppuccin_mocha_base}]"
        ''}
        
        # 📊 Right status with system info
        set -g status-right "#[fg=#{@catppuccin_mocha_surface0}]#[fg=#{@catppuccin_mocha_text},bg=#{@catppuccin_mocha_surface0}] %Y-%m-%d #[fg=#{@catppuccin_mocha_surface1},bg=#{@catppuccin_mocha_surface0}]#[fg=#{@catppuccin_mocha_text},bg=#{@catppuccin_mocha_surface1}] %H:%M #[fg=#{@catppuccin_mocha_peach},bg=#{@catppuccin_mocha_surface1}]#[fg=#{@catppuccin_mocha_base},bg=#{@catppuccin_mocha_peach},bold] #h "
        
        # 🪟 Window status
        set -g window-status-format "#[fg=#{@catppuccin_mocha_text},bg=#{@catppuccin_mocha_base}] #I:#W "
        set -g window-status-current-format "#[fg=#{@catppuccin_mocha_base},bg=#{@catppuccin_mocha_blue}]#[fg=#{@catppuccin_mocha_base},bg=#{@catppuccin_mocha_blue},bold] #I:#W #[fg=#{@catppuccin_mocha_blue},bg=#{@catppuccin_mocha_base}]"
        
        # 🎯 Pane borders
        set -g pane-border-style "fg=#{@catppuccin_mocha_surface0}"
        ${if cfg.planetMode then ''
          set -g pane-active-border-style "fg=#{@catppuccin_mocha_#{TMUX_PLANET_COLOR}}"
        '' else ''
          set -g pane-active-border-style "fg=#{@catppuccin_mocha_blue}"
        ''}
        
        # ⌨️ Key bindings
        
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
        
        ${optionalString cfg.planetMode ''
          # ⌨️ Planet-specific keybindings
          # Quick window switching with memorable keys
          bind-key c select-window -t :1   # Claude
          bind-key n select-window -t :2   # Neovim
          bind-key t select-window -t :3   # Terminal
          bind-key l select-window -t :4   # Logs
          
          # 🚀 Quick session switching
          bind-key M switch-client -t planet-mercury
          bind-key V switch-client -t planet-venus
          bind-key E switch-client -t planet-earth
          bind-key R switch-client -t planet-mars
          bind-key J switch-client -t planet-jupiter
        ''}
      '';
    };
    
    home.packages = with pkgs; (optionals cfg.planetMode [
      planetInitScript
      planetStatusScript
      planetSetupScript
    ]) ++ (optionals cfg.remoteOpener [
      remoteLinkOpenScript
    ]) ++ (optionals (cfg.planetMode && cfg.claudeNotifications) [
      claudeNotifyScript
      claudePlanetScript
    ]);
    
    # 📁 Create planet directories if planet mode is enabled
    home.file = mkIf cfg.planetMode (
      listToAttrs (map (planet: {
        name = "planets/${planet.name}/.keep";
        value = {
          text = "";
        };
      }) planetConfig.planets)
    );
    
    # 🌐 Set up environment for remote link opening
    home.sessionVariables = mkIf cfg.remoteOpener {
      BROWSER = "remote-link-open";
      DEFAULT_BROWSER = "remote-link-open";
    };
    
    # 🔧 Shell aliases for Claude commands
    programs.zsh.shellAliases = mkIf (cfg.planetMode && cfg.claudeNotifications) {
      claude = "claude-planet";
      cn = "claude-notify";
    };
  };
}