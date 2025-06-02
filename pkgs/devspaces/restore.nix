{ lib, writeScriptBin, bash, tmux, coreutils, devspace-init-single, devspace-setup }:

let
  theme = import ./theme.nix;
in
writeScriptBin "devspace-restore" ''
  #!${bash}/bin/bash
  # 🔄 Restore tmux sessions after restart/rebuild
  
  set -euo pipefail
  
  DEVSPACES=(${lib.concatStringsSep " " (map (s: ''"${s.name}"'') theme.spaces)})
  COLORS=(${lib.concatStringsSep " " (map (s: ''"${s.color}"'') theme.spaces)})
  ICONS=(${lib.concatStringsSep " " (map (s: ''"${s.icon}"'') theme.spaces)})
  DESCRIPTIONS=(
    ${lib.concatStringsSep "\n    " (map (s: ''"${s.description}"'') theme.spaces)}
  )
  
  # State directory for tmux resurrection
  STATE_DIR="$HOME/.local/state/tmux-devspaces"
  mkdir -p "$STATE_DIR"
  
  echo "🔄 Checking for existing tmux sessions..."
  
  # Start tmux server if not running
  ${tmux}/bin/tmux start-server 2>/dev/null || true
  
  # Check if tmux server is running and has any sessions
  existing_sessions=$(${tmux}/bin/tmux list-sessions -F '#S' 2>/dev/null || echo "")
  
  if [ -n "$existing_sessions" ]; then
    echo "✅ Found existing tmux sessions:"
    echo "$existing_sessions" | while read -r session; do
      echo "  - $session"
    done
    
    # Check each devspace session
    for i in "''${!DEVSPACES[@]}"; do
      devspace="''${DEVSPACES[$i]}"
      # Use numeric ID for session name (IDs start at 1)
      session_id=$((i + 1))
      session="devspace-$session_id"
      
      if echo "$existing_sessions" | grep -q "^$session$"; then
        echo "✅ Devspace '$devspace' session already exists"
      else
        echo "🔄 Recreating missing devspace '$devspace'..."
        # Use devspace-init-single to create it
        ${devspace-init-single}/bin/devspace-init-single "$devspace"
      fi
    done
  else
    echo "📊 No existing tmux sessions found"
    
    # Check for saved session state
    if [ -f "$STATE_DIR/sessions.txt" ]; then
      echo "📂 Found saved session state, attempting to restore..."
      
      # Debug: show file contents
      echo "📄 State file contents:"
      cat "$STATE_DIR/sessions.txt" || echo "  (empty or unreadable)"
      
      # Check if file is empty
      if [ ! -s "$STATE_DIR/sessions.txt" ]; then
        echo "⚠️  State file is empty, creating fresh sessions..."
        for i in "''${!DEVSPACES[@]}"; do
          devspace="''${DEVSPACES[$i]}"
          echo "🪐 Creating devspace '$devspace'..."
          ${devspace-init-single}/bin/devspace-init-single "$devspace"
        done
      else
        while IFS='|' read -r session_name window_count initialized project_path; do
          if [[ "$session_name" =~ ^devspace-([0-9]+)$ ]]; then
            session_id="''${BASH_REMATCH[1]}"
            # Convert session ID to devspace name (array is 0-indexed, IDs are 1-indexed)
            devspace_idx=$((session_id - 1))
            if [ $devspace_idx -ge 0 ] && [ $devspace_idx -lt ''${#DEVSPACES[@]} ]; then
              devspace="''${DEVSPACES[$devspace_idx]}"
              echo "🔄 Restoring devspace '$devspace' (was initialized: $initialized)"
              
              if [ "$initialized" = "true" ] && [ -n "$project_path" ] && [ -d "$project_path" ]; then
                # Restore as initialized devspace
                echo "  📁 Restoring with project: $project_path"
                
                # First create minimal session
                ${devspace-init-single}/bin/devspace-init-single "$devspace"
                
                # Then set up the project (which will expand it)
                ${devspace-setup}/bin/devspace-setup "$devspace" "$project_path" >/dev/null 2>&1 || echo "  ⚠️  Could not restore project link"
              else
                # Just create minimal session
                ${devspace-init-single}/bin/devspace-init-single "$devspace"
              fi
            fi
          fi
      done < "$STATE_DIR/sessions.txt"
      fi
      
      echo "✅ Session restoration complete"
    else
      echo "🌌 Creating fresh minimal devspace sessions..."
      # Create each devspace
      for i in "''${!DEVSPACES[@]}"; do
        devspace="''${DEVSPACES[$i]}"
        echo "🪐 Creating devspace '$devspace'..."
        ${devspace-init-single}/bin/devspace-init-single "$devspace"
      done
    fi
  fi
  
  # Save current state for next time
  echo "💾 Saving current session state..."
  
  # Clear any existing temp file
  rm -f "$STATE_DIR/sessions.txt.tmp"
  
  # Save each session (if any exist)
  if ${tmux}/bin/tmux list-sessions -F '#S' 2>/dev/null; then
    ${tmux}/bin/tmux list-sessions -F '#S' 2>/dev/null | while read -r session; do
    if [[ "$session" =~ ^devspace-([0-9]+)$ ]]; then
      session_id="''${BASH_REMATCH[1]}"
      # Convert session ID to devspace name
      devspace_idx=$((session_id - 1))
      if [ $devspace_idx -ge 0 ] && [ $devspace_idx -lt ''${#DEVSPACES[@]} ]; then
        devspace="''${DEVSPACES[$devspace_idx]}"
      
        # Get window count
        window_count=$(${tmux}/bin/tmux list-windows -t "$session" -F '#I' 2>/dev/null | wc -l)
        
        # Check if initialized
        initialized=$(${tmux}/bin/tmux show-environment -t "$session" TMUX_DEVSPACE_INITIALIZED 2>/dev/null | cut -d= -f2 || echo "false")
        
        # Get project path if linked
        project_path=""
        if [ -L "$HOME/devspaces/$devspace/project" ]; then
          project_path=$(readlink "$HOME/devspaces/$devspace/project")
        fi
        
        # Save state
        echo "$session|$window_count|$initialized|$project_path" >> "$STATE_DIR/sessions.txt.tmp"
      fi
    fi
    done
  fi
  
  # Atomic update
  if [ -f "$STATE_DIR/sessions.txt.tmp" ]; then
    mv "$STATE_DIR/sessions.txt.tmp" "$STATE_DIR/sessions.txt"
  else
    # No sessions to save, create empty state file
    touch "$STATE_DIR/sessions.txt"
  fi
  
  echo "✨ Devspace session management complete!"
''