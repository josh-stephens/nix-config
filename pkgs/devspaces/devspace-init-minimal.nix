{ lib, writeScriptBin, bash, tmux, figlet, cowsay }:

let
  theme = import ./theme.nix;
in
writeScriptBin "devspace-init" ''
  #!${bash}/bin/bash
  # 🚀 Initialize minimal devspace tmux sessions with setup prompts
  
  set -euo pipefail
  
  DEVSPACES=(${lib.concatStringsSep " " (map (s: ''"${s.name}"'') theme.spaces)})
  COLORS=(${lib.concatStringsSep " " (map (s: ''"${s.color}"'') theme.spaces)})
  ICONS=(${lib.concatStringsSep " " (map (s: ''"${s.icon}"'') theme.spaces)})
  DESCRIPTIONS=(
    ${lib.concatStringsSep "\n    " (map (s: ''"${s.description}"'') theme.spaces)}
  )
  
  echo "🌌 Initializing minimal development spaces..."
  
  for i in "''${!DEVSPACES[@]}"; do
    devspace="''${DEVSPACES[$i]}"
    color="''${COLORS[$i]}"
    icon="''${ICONS[$i]}"
    description="''${DESCRIPTIONS[$i]}"
    session="devspace-$devspace"
    
    if ! ${tmux}/bin/tmux has-session -t "$session" 2>/dev/null; then
      echo "🪐 Creating minimal devspace '$devspace'..."
      
      # Create session with environment variables
      TMUX_DEVSPACE="$devspace" TMUX_DEVSPACE_COLOR="$color" ${tmux}/bin/tmux new-session -d -s "$session" -n setup
      
      # Set environment for the session
      ${tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE "$devspace"
      ${tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE_COLOR "$color"
      ${tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE_INITIALIZED "false"
      
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
      ${tmux}/bin/tmux send-keys -t "$session:1" "echo '  $devspace .'" Enter
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
    else
      echo "✅ Devspace '$devspace' already exists"
    fi
  done
  
  echo "✨ All development spaces initialized!"
  ${tmux}/bin/tmux list-sessions
''