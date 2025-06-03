{ lib, writeScriptBin, bash, git, tmux, devspace-save-hook }:

let
  theme = import ./theme.nix;
  validNames = lib.concatStringsSep "|" (map (s: s.name) theme.spaces);
in

writeScriptBin "devspace-setup" ''
  #!${bash}/bin/bash
  # 🔧 Set up or change a devspace's project with automatic environment expansion
  
  set -euo pipefail
  
  # Colors for output
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color
  
  if [ $# -lt 1 ]; then
    echo "Usage: devspace-setup <name> [project-path]"
    echo "Note: This is usually called via the devspace shortcuts:"
    echo "  earth ~/projects/work/main-app"
    echo "  mars ."
    exit 1
  fi
  
  DEVSPACE="$1"
  PROJECT_PATH="''${2:-}"
  
  # Validate devspace name and get ID
  case "$DEVSPACE" in
    ${lib.concatStringsSep "\n    " (map (s: ''
    ${s.name})
      SESSION_ID="${toString s.id}"
      ;;'') theme.spaces)}
    *)
      echo -e "''${RED}❌ Invalid devspace: $DEVSPACE''${NC}"
      echo "Valid devspaces: ${lib.concatStringsSep ", " (map (s: s.name) theme.spaces)}"
      exit 1
      ;;
  esac
  
  DEVSPACE_DIR="$HOME/devspaces/$DEVSPACE"
  SESSION="devspace-$SESSION_ID"
  
  # Create devspace directory if needed
  mkdir -p "$DEVSPACE_DIR"
  
  # Helper function to expand minimal session to full environment
  expand_devspace() {
    local devspace="$1"
    # Get session ID from devspace name
    local session_id=""
    case "$devspace" in
      ${lib.concatStringsSep "\n      " (map (s: ''
      ${s.name})
        session_id="${toString s.id}"
        ;;'') theme.spaces)}
    esac
    local session="devspace-$session_id"
    
    # Check if already initialized
    local initialized=$(${tmux}/bin/tmux show-environment -t "$session" TMUX_DEVSPACE_INITIALIZED 2>/dev/null | cut -d= -f2 || echo "false")
    
    if [ "$initialized" = "true" ]; then
      return 0
    fi
    
    echo -e "''${BLUE}🔄 Expanding devspace to full environment...''${NC}"
    
    # Get the color from environment
    local color=$(${tmux}/bin/tmux show-environment -t "$session" TMUX_DEVSPACE_COLOR 2>/dev/null | cut -d= -f2 || echo "blue")
    
    # Check if we're inside this session
    local current_session=""
    if [ -n "''${TMUX:-}" ]; then
      current_session=$(${tmux}/bin/tmux display-message -p '#S' 2>/dev/null || echo "")
    fi
    
    if [ "$current_session" = "$session" ]; then
      # We're inside - rename current window to term
      echo -e "''${GREEN}🔄 Transforming current session...''${NC}"
      ${tmux}/bin/tmux rename-window -t "$session:1" term
      
      # Create the other windows
      ${tmux}/bin/tmux new-window -t "$session:2" -n claude
      ${tmux}/bin/tmux new-window -t "$session:3" -n nvim
      ${tmux}/bin/tmux new-window -t "$session:4" -n logs
      
      # Disable automatic rename for all windows
      for window in 1 2 3 4; do
        ${tmux}/bin/tmux set-window-option -t "$session:$window" automatic-rename off
        ${tmux}/bin/tmux set-window-option -t "$session:$window" allow-rename off
      done
      
      # Move term to position 3 and claude to position 1
      ${tmux}/bin/tmux swap-window -s "$session:1" -t "$session:3"
      
      # Now claude is at 1, nvim at 2, term at 3, logs at 4
      # Let's make sure they're in the right order
      ${tmux}/bin/tmux move-window -s "$session:claude" -t "$session:1" 2>/dev/null || true
      ${tmux}/bin/tmux move-window -s "$session:nvim" -t "$session:2" 2>/dev/null || true
      ${tmux}/bin/tmux move-window -s "$session:term" -t "$session:3" 2>/dev/null || true
      ${tmux}/bin/tmux move-window -s "$session:logs" -t "$session:4" 2>/dev/null || true
      
      # Stay in current window (which is now term)
      echo -e "''${GREEN}✨ Devspace expanded! Windows: claude, nvim, term, logs''${NC}"
    else
      # We're outside - recreate the session with full windows
      # Get project path
      local project_path=""
      if [ -L "$HOME/devspaces/$devspace/project" ]; then
        project_path=$(readlink "$HOME/devspaces/$devspace/project")
      fi
      
      # Kill and recreate the session properly
      ${tmux}/bin/tmux kill-session -t "$session" 2>/dev/null || true
      
      # Get icon from theme
      local icon=""
      case "$devspace" in
        ${lib.concatStringsSep "\n        " (map (s: ''
        ${s.name}) icon="${s.icon}" ;;'') theme.spaces)}
      esac
      
      # Set environment variables in tmux session (will be inherited by new windows)
      ${tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE "$devspace" 2>/dev/null || true
      ${tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE_COLOR "$color" 2>/dev/null || true
      ${tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE_ICON "$icon" 2>/dev/null || true
      
      # Create new session with all windows
      # Use -e to set environment variables for each window at creation time
      if [ -n "$project_path" ]; then
        ${tmux}/bin/tmux new-session -d -s "$session" -n claude -c "$project_path" \
          -e TMUX_DEVSPACE="$devspace" -e TMUX_DEVSPACE_COLOR="$color" -e TMUX_DEVSPACE_ICON="$icon"
        ${tmux}/bin/tmux new-window -t "$session:2" -n nvim -c "$project_path" \
          -e TMUX_DEVSPACE="$devspace" -e TMUX_DEVSPACE_COLOR="$color" -e TMUX_DEVSPACE_ICON="$icon"
        ${tmux}/bin/tmux new-window -t "$session:3" -n term -c "$project_path" \
          -e TMUX_DEVSPACE="$devspace" -e TMUX_DEVSPACE_COLOR="$color" -e TMUX_DEVSPACE_ICON="$icon"
        ${tmux}/bin/tmux new-window -t "$session:4" -n logs -c "$project_path" \
          -e TMUX_DEVSPACE="$devspace" -e TMUX_DEVSPACE_COLOR="$color" -e TMUX_DEVSPACE_ICON="$icon"
      else
        ${tmux}/bin/tmux new-session -d -s "$session" -n claude \
          -e TMUX_DEVSPACE="$devspace" -e TMUX_DEVSPACE_COLOR="$color" -e TMUX_DEVSPACE_ICON="$icon"
        ${tmux}/bin/tmux new-window -t "$session:2" -n nvim \
          -e TMUX_DEVSPACE="$devspace" -e TMUX_DEVSPACE_COLOR="$color" -e TMUX_DEVSPACE_ICON="$icon"
        ${tmux}/bin/tmux new-window -t "$session:3" -n term \
          -e TMUX_DEVSPACE="$devspace" -e TMUX_DEVSPACE_COLOR="$color" -e TMUX_DEVSPACE_ICON="$icon"
        ${tmux}/bin/tmux new-window -t "$session:4" -n logs \
          -e TMUX_DEVSPACE="$devspace" -e TMUX_DEVSPACE_COLOR="$color" -e TMUX_DEVSPACE_ICON="$icon"
      fi
      
      # Disable automatic rename for all windows
      for window in 1 2 3 4; do
        ${tmux}/bin/tmux set-window-option -t "$session:$window" automatic-rename off
        ${tmux}/bin/tmux set-window-option -t "$session:$window" allow-rename off
      done
      
      # Re-set environment variables in session for consistency
      ${tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE "$devspace"
      ${tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE_COLOR "$color"
      ${tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE_ICON "$icon"
      
      # Wait a moment for shells to initialize
      sleep 0.5
      
      # Show welcome banner in all windows
      for window in 1 2 3 4; do
        ${tmux}/bin/tmux send-keys -t "$session:$window" "clear && devspace-welcome $devspace" Enter
      done
      
      # After a brief pause, start applications
      sleep 0.2
      
      # If we have a project path, cd to it first
      if [ -n "$project_path" ] && [ -d "$project_path" ]; then
        # Start claude wrapper in window 1
        ${tmux}/bin/tmux send-keys -t "$session:1" "cd '$project_path' && claude" Enter
        
        # Start nvim in window 2 with current directory
        ${tmux}/bin/tmux send-keys -t "$session:2" "cd '$project_path' && nvim ." Enter
      else
        # No project path, just start the applications
        ${tmux}/bin/tmux send-keys -t "$session:1" "claude" Enter
        ${tmux}/bin/tmux send-keys -t "$session:2" "nvim" Enter
      fi
      
      echo -e "''${GREEN}✨ Devspace recreated with full environment!''${NC}"
    fi
    
    # Mark as initialized and store the project path
    ${tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE_INITIALIZED "true"
    if [ -n "$project_path" ]; then
      ${tmux}/bin/tmux set-environment -t "$session" TMUX_DEVSPACE_PROJECT "$project_path"
    fi
  }
  
  # Helper function to get the main repository from a path
  get_main_repo() {
    local path="$1"
    if [ ! -d "$path/.git" ] && [ ! -f "$path/.git" ]; then
      echo ""
      return
    fi
    
    if [ -f "$path/.git" ]; then
      # It's a worktree, get the main repo
      local gitdir=$(cat "$path/.git" | sed 's/gitdir: //')
      echo $(dirname $(dirname "$gitdir"))
    else
      # It's the main repo
      echo "$path"
    fi
  }
  
  # Helper function to check if a branch is merged
  is_branch_merged() {
    local repo="$1"
    local branch="$2"
    local main_branch=$(${git}/bin/git -C "$repo" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
    
    # Check if branch is merged into main
    if ${git}/bin/git -C "$repo" merge-base --is-ancestor "$branch" "origin/$main_branch" 2>/dev/null; then
      return 0
    fi
    return 1
  }
  
  # Helper function to clean orphaned worktrees
  clean_orphaned_worktrees() {
    local devspace="$1"
    local devspace_dir="$HOME/devspaces/$devspace"
    
    if [ ! -d "$devspace_dir/worktrees" ]; then
      return
    fi
    
    # Get main repo from current setup
    local current_project=""
    if [ -L "$devspace_dir/project" ]; then
      current_project=$(readlink "$devspace_dir/project")
    fi
    
    local main_repo=$(get_main_repo "$current_project")
    if [ -z "$main_repo" ]; then
      return
    fi
    
    # Check each worktree
    for worktree in "$devspace_dir/worktrees"/*; do
      if [ -d "$worktree" ]; then
        local branch=$(basename "$worktree")
        
        # Check if this worktree is the current project
        if [ "$worktree" = "$current_project" ]; then
          continue
        fi
        
        # Check if branch is merged
        if is_branch_merged "$main_repo" "$branch"; then
          echo -e "''${GREEN}🧹 Cleaning merged worktree: $branch''${NC}"
          ${git}/bin/git -C "$main_repo" worktree remove "$worktree" --force 2>/dev/null || true
        fi
      fi
    done
    
    # Clean up empty directory
    rmdir "$devspace_dir/worktrees" 2>/dev/null || true
  }
  
  # If no project path specified, show current setup and clean orphaned worktrees
  if [ -z "$PROJECT_PATH" ]; then
    echo -e "''${BLUE}🪐 Current setup for $DEVSPACE:''${NC}"
    if [ -L "$DEVSPACE_DIR/project" ]; then
      echo "  📁 Project: $(readlink "$DEVSPACE_DIR/project")"
      
      # Clean orphaned worktrees
      clean_orphaned_worktrees "$DEVSPACE"
    else
      echo "  📁 No project linked"
    fi
    
    # Show session status
    if ${tmux}/bin/tmux has-session -t "$SESSION" 2>/dev/null; then
      local initialized=$(${tmux}/bin/tmux show-environment -t "$SESSION" TMUX_DEVSPACE_INITIALIZED 2>/dev/null | cut -d= -f2 || echo "false")
      if [ "$initialized" = "true" ]; then
        echo "  🟢 Session: fully initialized"
      else
        echo "  🟡 Session: minimal (waiting for project)"
      fi
    else
      echo "  🔴 Session: not running"
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
    echo -e "''${RED}❌ Project path does not exist: $PROJECT_PATH''${NC}"
    exit 1
  fi
  
  # Check if we're changing from an existing project
  if [ -L "$DEVSPACE_DIR/project" ]; then
    current=$(readlink "$DEVSPACE_DIR/project")
    
    # If it's the same, we're done
    if [ "$current" = "$PROJECT_PATH" ]; then
      echo -e "''${GREEN}✅ $DEVSPACE is already linked to $PROJECT_PATH''${NC}"
      
      # Ensure session is expanded
      if ${tmux}/bin/tmux has-session -t "$SESSION" 2>/dev/null; then
        expand_devspace "$DEVSPACE"
      fi
      
      exit 0
    fi
    
    # Check if current is a worktree with uncommitted changes
    if [[ "$current" =~ "$DEVSPACE_DIR/worktrees" ]] && [ -d "$current/.git" ]; then
      # Check for uncommitted changes
      if ! ${git}/bin/git -C "$current" diff --quiet || ! ${git}/bin/git -C "$current" diff --cached --quiet; then
        echo -e "''${RED}❌ Current worktree has uncommitted changes''${NC}"
        echo "Please commit or stash changes in: $current"
        exit 1
      fi
      
      # Check if branch is unmerged
      local branch=$(basename "$current")
      local main_repo=$(get_main_repo "$current")
      if ! is_branch_merged "$main_repo" "$branch"; then
        echo -e "''${YELLOW}⚠️  Current worktree branch '$branch' is not merged''${NC}"
        echo "Worktree will be preserved at: $current"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          exit 1
        fi
      fi
    fi
  fi
  
  # Get the main repository for the new project
  main_repo=$(get_main_repo "$PROJECT_PATH")
  
  # If it's a git repo, check if other devspaces use it
  if [ -n "$main_repo" ]; then
    # Find other devspaces using this repository
    other_devspaces=()
    for space in ${lib.concatStringsSep " " (map (s: s.name) theme.spaces)}; do
      if [ "$space" != "$DEVSPACE" ] && [ -L "$HOME/devspaces/$space/project" ]; then
        other_project=$(readlink "$HOME/devspaces/$space/project")
        other_main=$(get_main_repo "$other_project")
        
        if [ "$other_main" = "$main_repo" ]; then
          other_devspaces+=("$space")
        fi
      fi
    done
    
    # If others are using this repo, automatically create a worktree
    if [ ''${#other_devspaces[@]} -gt 0 ]; then
      echo -e "''${YELLOW}⚠️  Repository is also used by: ''${other_devspaces[*]}''${NC}"
      echo -e "''${BLUE}🌳 Creating automatic worktree for isolation...''${NC}"
      
      # Generate branch name based on devspace
      local date_suffix=$(date +%Y%m%d-%H%M%S)
      local branch_name="devspace-$DEVSPACE-$date_suffix"
      
      # Create worktrees directory
      mkdir -p "$DEVSPACE_DIR/worktrees"
      
      # Create the worktree
      local worktree_dir="$DEVSPACE_DIR/worktrees/$branch_name"
      ${git}/bin/git -C "$main_repo" worktree add -b "$branch_name" "$worktree_dir"
      
      # Link to the worktree instead
      rm -f "$DEVSPACE_DIR/project"
      ln -s "$worktree_dir" "$DEVSPACE_DIR/project"
      
      echo -e "''${GREEN}✅ Created worktree: $branch_name''${NC}"
      echo -e "''${GREEN}✅ Linked $DEVSPACE to isolated worktree''${NC}"
      
      PROJECT_PATH="$worktree_dir"
    else
      # No conflicts, create direct symlink
      rm -f "$DEVSPACE_DIR/project"
      ln -s "$PROJECT_PATH" "$DEVSPACE_DIR/project"
      echo -e "''${GREEN}✅ Linked $DEVSPACE to $PROJECT_PATH''${NC}"
    fi
  else
    # Not a git repo, just link directly
    rm -f "$DEVSPACE_DIR/project"
    ln -s "$PROJECT_PATH" "$DEVSPACE_DIR/project"
    echo -e "''${GREEN}✅ Linked $DEVSPACE to $PROJECT_PATH''${NC}"
  fi
  
  # Clean orphaned worktrees
  clean_orphaned_worktrees "$DEVSPACE"
  
  # Handle tmux session
  if ${tmux}/bin/tmux has-session -t "$SESSION" 2>/dev/null; then
    # Update the project path in session environment
    ${tmux}/bin/tmux set-environment -t "$SESSION" TMUX_DEVSPACE_PROJECT "$PROJECT_PATH"
    
    # Expand minimal session to full environment if needed
    expand_devspace "$DEVSPACE"
    
    # Update working directories in all windows
    for window in 1 2 3 4; do
      if ${tmux}/bin/tmux list-windows -t "$SESSION" -F '#I' | grep -q "^$window$"; then
        ${tmux}/bin/tmux send-keys -t "$SESSION:$window" C-c "cd '$PROJECT_PATH'" Enter
      fi
    done
    
    # Start nvim in window 2 if it's not already running
    ${tmux}/bin/tmux send-keys -t "$SESSION:2" C-c "nvim" Enter
    
    echo -e "''${GREEN}📍 Updated working directory in tmux session''${NC}"
    echo -e "''${GREEN}✨ Devspace $DEVSPACE is ready for development!''${NC}"
    
    # Save state after successful setup
    ${devspace-save-hook}/bin/devspace-save-hook
  else
    echo -e "''${YELLOW}⚠️  Tmux session not running. Connect with: $DEVSPACE''${NC}"
  fi
''