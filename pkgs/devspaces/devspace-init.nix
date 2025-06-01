{ lib, writeScriptBin, bash, tmux }:

let
  theme = import ./theme.nix;
in
writeScriptBin "devspace-init" ''
  #!${bash}/bin/bash
  # 🚀 Initialize all development space tmux sessions
  
  set -euo pipefail
  
  DEVSPACES=(${lib.concatStringsSep " " (map (s: ''"${s.name}"'') theme.spaces)})
  COLORS=(${lib.concatStringsSep " " (map (s: ''"${s.color}"'') theme.spaces)})
  
  echo "🌌 Initializing development spaces..."
  
  for i in "''${!DEVSPACES[@]}"; do
    devspace="''${DEVSPACES[$i]}"
    color="''${COLORS[$i]}"
    session="devspace-$devspace"
    
    if ! ${tmux}/bin/tmux has-session -t "$session" 2>/dev/null; then
      echo "🪐 Creating devspace '$devspace' (theme: $color)..."
      
      # Create session with environment variables
      TMUX_DEVSPACE="$devspace" TMUX_DEVSPACE_COLOR="$color" ${tmux}/bin/tmux new-session -d -s "$session" -n claude
      
      # Set environment for the session
      ${tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE "$devspace"
      ${tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE_COLOR "$color"
      
      # Create default windows
      ${tmux}/bin/tmux new-window -t "$session:2" -n nvim
      ${tmux}/bin/tmux new-window -t "$session:3" -n term
      ${tmux}/bin/tmux new-window -t "$session:4" -n logs
      
      # Set working directory if it exists
      if [ -d "$HOME/devspaces/$devspace" ]; then
        ${tmux}/bin/tmux send-keys -t "$session:1" "cd ~/devspaces/$devspace" Enter
        ${tmux}/bin/tmux send-keys -t "$session:2" "cd ~/devspaces/$devspace" Enter
        ${tmux}/bin/tmux send-keys -t "$session:3" "cd ~/devspaces/$devspace" Enter
      fi
      
      # Start log monitoring in window 4
      ${tmux}/bin/tmux send-keys -t "$session:4" "tail -f ~/.claude-code-$devspace.log 2>/dev/null || echo '📋 Log file will appear when Claude starts...'" Enter
    else
      echo "✅ Devspace '$devspace' already exists"
    fi
  done
  
  echo "✨ All development spaces initialized!"
  ${tmux}/bin/tmux list-sessions
''