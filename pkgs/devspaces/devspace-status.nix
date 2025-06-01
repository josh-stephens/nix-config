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
    session="devspace-$devspace"
    
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
    else
      echo "  ❌ Status: not initialized"
    fi
    echo
  done
''