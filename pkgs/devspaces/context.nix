{ writeScriptBin, bash }:

writeScriptBin "devspace-context" ''
  #!${bash}/bin/bash
  # 🎯 Detect current devspace context from tmux session
  
  # Check if we're in a tmux session
  if [ -n "$TMUX" ]; then
    # Get the session name
    session_name=$(tmux display-message -p '#S' 2>/dev/null || echo "")
    
    # Check if it's a devspace session
    if [[ "$session_name" =~ ^devspace-(.+)$ ]]; then
      echo "''${BASH_REMATCH[1]}"
      exit 0
    fi
  fi
  
  # Check environment variable (set by devspace sessions)
  if [ -n "$TMUX_DEVSPACE" ]; then
    echo "$TMUX_DEVSPACE"
    exit 0
  fi
  
  # Not in a devspace context
  exit 1
''