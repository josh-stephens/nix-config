{ lib, writeScriptBin, bash, tmux }:

let
  theme = import ./theme.nix;
in
writeScriptBin "devspace-expand" ''
  #!${bash}/bin/bash
  # 🔄 Expand a minimal devspace into a full development environment
  
  set -euo pipefail
  
  if [ $# -lt 1 ]; then
    echo "Usage: devspace-expand <devspace>"
    exit 1
  fi
  
  DEVSPACE="$1"
  SESSION="devspace-$DEVSPACE"
  
  # Check if session exists
  if ! ${tmux}/bin/tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "❌ Devspace session '$DEVSPACE' does not exist"
    exit 1
  fi
  
  # Check if already initialized
  INITIALIZED=$(${tmux}/bin/tmux show-environment -t "$SESSION" TMUX_DEVSPACE_INITIALIZED 2>/dev/null | cut -d= -f2 || echo "false")
  
  if [ "$INITIALIZED" = "true" ]; then
    echo "✅ Devspace '$DEVSPACE' is already expanded"
    exit 0
  fi
  
  echo "🔄 Expanding devspace '$DEVSPACE' to full environment..."
  
  # Get the color from environment
  COLOR=$(${tmux}/bin/tmux show-environment -t "$SESSION" TMUX_DEVSPACE_COLOR 2>/dev/null | cut -d= -f2 || echo "blue")
  
  # Kill the setup window
  ${tmux}/bin/tmux kill-window -t "$SESSION:setup" 2>/dev/null || true
  
  # Create the full environment windows
  ${tmux}/bin/tmux new-window -t "$SESSION:1" -n claude
  ${tmux}/bin/tmux new-window -t "$SESSION:2" -n nvim
  ${tmux}/bin/tmux new-window -t "$SESSION:3" -n term
  ${tmux}/bin/tmux new-window -t "$SESSION:4" -n logs
  
  # Set working directory if project is linked
  if [ -L "$HOME/devspaces/$DEVSPACE/project" ]; then
    PROJECT_PATH=$(readlink "$HOME/devspaces/$DEVSPACE/project")
    
    # Send cd commands to windows
    ${tmux}/bin/tmux send-keys -t "$SESSION:1" "cd '$PROJECT_PATH'" Enter
    ${tmux}/bin/tmux send-keys -t "$SESSION:2" "cd '$PROJECT_PATH'" Enter
    ${tmux}/bin/tmux send-keys -t "$SESSION:3" "cd '$PROJECT_PATH'" Enter
    
    # Start nvim in window 2
    ${tmux}/bin/tmux send-keys -t "$SESSION:2" "nvim" Enter
  else
    # No project linked, show helpful messages
    ${tmux}/bin/tmux send-keys -t "$SESSION:1" "echo '💡 Use claude-devspace to start Claude Code in this devspace'" Enter
    ${tmux}/bin/tmux send-keys -t "$SESSION:2" "echo '💡 No project linked yet. Use: $DEVSPACE /path/to/project'" Enter
    ${tmux}/bin/tmux send-keys -t "$SESSION:3" "echo '🚀 Terminal ready. Link a project with: $DEVSPACE /path/to/project'" Enter
  fi
  
  # Start log monitoring in window 4
  ${tmux}/bin/tmux send-keys -t "$SESSION:4" "tail -f ~/.claude-code-$DEVSPACE.log 2>/dev/null || echo '📋 Log file will appear when Claude starts...'" Enter
  
  # Mark as initialized
  ${tmux}/bin/tmux set-environment -t "$SESSION" TMUX_DEVSPACE_INITIALIZED "true"
  
  # Switch to window 1
  ${tmux}/bin/tmux select-window -t "$SESSION:1"
  
  echo "✅ Devspace '$DEVSPACE' expanded successfully!"
''