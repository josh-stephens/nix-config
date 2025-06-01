{ writeScriptBin, bash, tmux }:

writeScriptBin "save_session_state" ''
  #!${bash}/bin/bash
  # 💾 Save current tmux session state
  
  STATE_DIR="$HOME/.local/state/tmux-devspaces"
  mkdir -p "$STATE_DIR"
  
  # Clear previous state
  > "$STATE_DIR/sessions.txt"
  
  # Save each session's state
  ${tmux}/bin/tmux list-sessions -F '#S' 2>/dev/null | while read -r session; do
    if [[ "$session" =~ ^devspace-(.+)$ ]]; then
      devspace="''${BASH_REMATCH[1]}"
      
      # Get window count
      window_count=$(${tmux}/bin/tmux list-windows -t "$session" -F '#I' 2>/dev/null | wc -l)
      
      # Check if initialized (has TMUX_DEVSPACE_INITIALIZED set to true)
      initialized=$(${tmux}/bin/tmux show-environment -t "$session" TMUX_DEVSPACE_INITIALIZED 2>/dev/null | cut -d= -f2 || echo "false")
      
      # Get project path if linked
      project_path=""
      if [ -L "$HOME/devspaces/$devspace/project" ]; then
        project_path=$(readlink "$HOME/devspaces/$devspace/project")
      fi
      
      # Save state
      echo "$session|$window_count|$initialized|$project_path" >> "$STATE_DIR/sessions.txt"
    fi
  done
  
  # Also save general tmux state using tmux-resurrect format if desired
  # This is for future enhancement
''