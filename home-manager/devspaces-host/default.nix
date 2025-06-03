{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.devspaces;
  
  # Import devspace theme configuration
  theme = import ../../pkgs/devspaces/theme.nix;
  devspaceConfig = {
    devspaces = map (s: {
      id = s.id;
      name = s.name;
      icon = s.icon;
      color = s.color;
      description = "${s.icon} ${s.name} - ${s.description}";
      hotkey = s.hotkey;
    }) theme.spaces;
  };

  # 🚀 Devspace management scripts
  devspaceInitScript = pkgs.writeScriptBin "devspace-init" ''
    #!${pkgs.bash}/bin/bash
    # 🚀 Initialize all devspace tmux sessions
    
    set -euo pipefail
    
    DEVSPACE_IDS=(${concatStringsSep " " (map (p: ''"${toString p.id}"'') devspaceConfig.devspaces)})
    DEVSPACE_NAMES=(${concatStringsSep " " (map (p: ''"${p.name}"'') devspaceConfig.devspaces)})
    DEVSPACE_ICONS=(${concatStringsSep " " (map (p: ''"${p.icon}"'') devspaceConfig.devspaces)})
    COLORS=(${concatStringsSep " " (map (p: ''"${p.color}"'') devspaceConfig.devspaces)})
    
    echo "🌌 Initializing devspace development environments..."
    
    for i in "''${!DEVSPACE_IDS[@]}"; do
      id="''${DEVSPACE_IDS[$i]}"
      name="''${DEVSPACE_NAMES[$i]}"
      icon="''${DEVSPACE_ICONS[$i]}"
      color="''${COLORS[$i]}"
      session="devspace-$id"
      
      if ! ${pkgs.tmux}/bin/tmux has-session -t "$session" 2>/dev/null; then
        echo "$icon Creating $name (color: $color)..."
        
        # Create session with environment variables
        TMUX_DEVSPACE="$name" TMUX_DEVSPACE_COLOR="$color" TMUX_DEVSPACE_ICON="$icon" TMUX_DEVSPACE_ID="$id" ${pkgs.tmux}/bin/tmux new-session -d -s "$session" -n claude
        
        # Set environment for the session
        ${pkgs.tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE "$name"
        ${pkgs.tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE_COLOR "$color"
        ${pkgs.tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE_ICON "$icon"
        ${pkgs.tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE_ID "$id"
        
        # Create default windows with proper names
        ${pkgs.tmux}/bin/tmux new-window -t "$session:2" -n nvim
        ${pkgs.tmux}/bin/tmux new-window -t "$session:3" -n term
        ${pkgs.tmux}/bin/tmux new-window -t "$session:4" -n logs
        
        # Set working directory if it exists
        if [ -d "$HOME/devspaces/$name" ]; then
          ${pkgs.tmux}/bin/tmux send-keys -t "$session:1" "cd ~/devspaces/$name" Enter
          ${pkgs.tmux}/bin/tmux send-keys -t "$session:2" "cd ~/devspaces/$name" Enter
          ${pkgs.tmux}/bin/tmux send-keys -t "$session:3" "cd ~/devspaces/$name" Enter
        fi
        
        # Start log monitoring in window 4
        ${pkgs.tmux}/bin/tmux send-keys -t "$session:4" "tail -f ~/.claude-code-$name.log 2>/dev/null || echo '📋 Log file will appear when Claude starts...'" Enter
      else
        echo "✅ $name already exists"
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
    
    DEVSPACE_IDS=(${concatStringsSep " " (map (p: ''"${toString p.id}"'') devspaceConfig.devspaces)})
    DEVSPACE_NAMES=(${concatStringsSep " " (map (p: ''"${p.name}"'') devspaceConfig.devspaces)})
    
    for i in "''${!DEVSPACE_IDS[@]}"; do
      id="''${DEVSPACE_IDS[$i]}"
      name="''${DEVSPACE_NAMES[$i]}"
      desc="''${DESCRIPTIONS[$i]}"
      session="devspace-$id"
      
      echo "$desc"
      
      if ${pkgs.tmux}/bin/tmux has-session -t "$session" 2>/dev/null; then
        # Get current window
        current_window=$(${pkgs.tmux}/bin/tmux display-message -t "$session" -p '#W' 2>/dev/null || echo "unknown")
        
        # Check for linked project
        if [ -L "$HOME/devspaces/$name/project" ]; then
          project=$(readlink "$HOME/devspaces/$name/project" | xargs basename)
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
  options.programs.devspaces = {
    enable = mkEnableOption "devspace development environments";
    
    claudeNotifications = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Claude Code notification wrapper";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      devspaceInitScript
      devspaceStatusScript
      devspaceSetupScript
    ];

    # Create devspace directories
    home.file = listToAttrs (map (devspace: {
      name = "devspaces/${devspace.name}/.keep";
      value = {
        text = "";
      };
    }) devspaceConfig.devspaces);
    
    # Auto-connect to devspace based on DEVSPACE_ID environment variable (from ET)
    programs.zsh.initContent = ''
      # Check if DEVSPACE_ID is set (from ET connection)
      if [ -n "$DEVSPACE_ID" ] && [ -z "$TMUX" ]; then
        # Extract numeric ID from format "id-3"
        devspace_id="''${DEVSPACE_ID#id-}"
        
        # Attach to the corresponding tmux session
        session="devspace-$devspace_id"
        if tmux has-session -t "$session" 2>/dev/null; then
          exec tmux attach-session -t "$session"
        else
          # Session doesn't exist, create it first
          # Get devspace name from ID
          case "$devspace_id" in
            ${lib.concatStringsSep "\n            " (map (s: ''${toString s.id}) devspace_name="${s.name}" ;;'') devspaceConfig.devspaces)}
            *) devspace_name="unknown" ;;
          esac
          
          # Run the devspace command to initialize and attach
          if command -v "$devspace_name" &>/dev/null; then
            exec "$devspace_name"
          else
            echo "⚠️  Devspace $devspace_name (ID: $devspace_id) not found"
          fi
        fi
      fi
    '';
  };
}