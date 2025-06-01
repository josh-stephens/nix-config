{ lib, writeScriptBin, bash, tmux, figlet, cowsay }:

let
  theme = import ./theme.nix;
  spaceMap = lib.listToAttrs (map (s: { name = s.name; value = s; }) theme.spaces);
in
writeScriptBin "devspace-init-single" ''
  #!${bash}/bin/bash
  # 🚀 Initialize a single minimal devspace tmux session
  
  set -euo pipefail
  
  if [ $# -lt 1 ]; then
    echo "Usage: devspace-init-single <devspace-name>"
    exit 1
  fi
  
  devspace="$1"
  
  # Validate devspace name and get its config
  case "$devspace" in
    ${lib.concatStringsSep "\n    " (map (s: ''
    ${s.name})
      color="${s.color}"
      icon="${s.icon}"
      description="${s.description}"
      ;;'') theme.spaces)}
    *)
      echo "❌ Unknown devspace: $devspace"
      echo "Valid devspaces: ${lib.concatStringsSep ", " (map (s: s.name) theme.spaces)}"
      exit 1
      ;;
  esac
  
  session="devspace-$devspace"
  
  if ${tmux}/bin/tmux has-session -t "$session" 2>/dev/null; then
    echo "✅ Devspace '$devspace' already exists"
    exit 0
  fi
  
  echo "🪐 Creating minimal devspace '$devspace'..."
  
  # Create session with environment variables and start user's default shell
  # Use the user's default shell, which will load all their configs
  TMUX_DEVSPACE="$devspace" TMUX_DEVSPACE_COLOR="$color" ${tmux}/bin/tmux new-session -d -s "$session" -n setup
  
  # Set environment for the session
  ${tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE "$devspace"
  ${tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE_COLOR "$color"
  ${tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE_INITIALIZED "false"
  
  # Wait a moment for shell to start
  sleep 0.1
  
  # Create the setup prompt in the window
  ${tmux}/bin/tmux send-keys -t "$session:1" "clear" Enter
  
  # Display welcome message
  ${tmux}/bin/tmux send-keys -t "$session:1" "${figlet}/bin/figlet -f slant '$devspace' | ${cowsay}/bin/cowsay -n -f tux" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo '$icon Devspace: $devspace'" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo '📝 Purpose: $description'" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo '⚡ This devspace is not initialized yet!'" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo 'To set up this devspace, run:'" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo '  $devspace /path/to/project'" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo 'Examples:'" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo '  $devspace ~/Work/my-project'" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo '  $devspace .                  # Use current directory'" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo 'Other commands:'" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo '  $devspace status              # Show current configuration'" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo '  $devspace worktree create feature/xyz  # Create a git worktree'" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo 'Once initialized, this window will transform into a full development environment'" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo 'with claude, nvim, term, and logs windows.'" Enter
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo" Enter
  
  # Keep the prompt alive
  ${tmux}/bin/tmux send-keys -t "$session:1" "echo '💡 Press Enter to refresh this message...'; read" Enter
  
  echo "✅ Created minimal devspace '$devspace'"
''