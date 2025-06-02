{ lib, writeScriptBin, bash, tmux }:

let
  theme = import ./theme.nix;
in
writeScriptBin "devspace-status" ''
  #!${bash}/bin/bash
  # 📊 Show status of all devspace sessions
  
  echo "🌌 Development Spaces Status"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo
  
  DEVSPACES=(${lib.concatStringsSep " " (map (s: ''"${s.name}"'') theme.spaces)})
  DESCRIPTIONS=(
    ${lib.concatStringsSep "\n    " (map (s: ''"${s.icon} ${s.name} - ${s.description}"'') theme.spaces)}
  )
  HOTKEYS=(${lib.concatStringsSep " " (map (s: ''"${s.hotkey}"'') theme.spaces)})
  
  for i in "''${!DEVSPACES[@]}"; do
    devspace="''${DEVSPACES[$i]}"
    desc="''${DESCRIPTIONS[$i]}"
    hotkey="''${HOTKEYS[$i]}"
    session_id=$((i + 1))  # IDs start at 1
    session="devspace-$session_id"
    
    echo "$desc (Alt-$hotkey)"
    
    if ${tmux}/bin/tmux has-session -t "$session" 2>/dev/null; then
      # Get current window
      current_window=$(${tmux}/bin/tmux display-message -t "$session" -p '#W' 2>/dev/null || echo "unknown")
      
      # Check for linked project
      if [ -L "$HOME/devspaces/$devspace/project" ]; then
        project=$(readlink "$HOME/devspaces/$devspace/project" | xargs basename)
        echo "  📁 Project: $project"
      else
        echo "  📁 Project: none"
      fi
      
      echo "  🪟 Current window: $current_window"
      echo "  ✅ Status: active"
      echo "  💡 Connect: $devspace connect"
    else
      echo "  ❌ Status: not initialized"
      echo "  💡 Initialize: devspace-init"
    fi
    echo
  done
  
  echo "Quick Commands:"
  echo "  Link project:     <devspace> <path>"
  echo "  Show status:      <devspace> status"
  echo "  Connect to tmux:  <devspace> connect"
  echo "  Create worktree:  <devspace> worktree create <branch>"
  echo ""
  echo "Example: earth ~/projects/myapp"
''