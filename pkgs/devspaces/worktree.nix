{ lib, writeScriptBin, bash, git, tmux }:

let
  theme = import ./theme.nix;
  validNames = lib.concatStringsSep "|" (map (s: s.name) theme.spaces);
in

writeScriptBin "devspace-worktree" ''
  #!${bash}/bin/bash
  # 🌳 Manage git worktrees for devspaces
  
  # Helper to get session ID from devspace name
  get_session_id() {
    local devspace="$1"
    case "$devspace" in
      ${lib.concatStringsSep "\n      " (map (s: ''
      ${s.name})
        echo "${toString s.id}"
        return 0
        ;;'') theme.spaces)}
      *)
        echo "Unknown devspace: $devspace" >&2
        return 1
        ;;
    esac
  }
  
  set -euo pipefail
  
  # Colors for output
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color
  
  usage() {
    echo "Usage: devspace-worktree <command> [devspace] [options]"
    echo "       OR called via: <devspace> worktree <command> [options]"
    echo
    echo "Commands:"
    echo "  create <branch>    Create a worktree for the devspace"
    echo "  list               List worktrees for a devspace"
    echo "  clean              Remove worktree for a devspace"
    echo "  status             Show all devspace worktree status"
    echo
    echo "Examples (when called directly):"
    echo "  devspace-worktree create earth feature/new-ui"
    echo "  devspace-worktree list mars"
    echo "  devspace-worktree clean earth"
    echo
    echo "Examples (when called via devspace commands):"
    echo "  earth worktree create feature/new-ui"
    echo "  mars worktree list"
    echo "  earth worktree clean"
    echo
    echo "Note: Use the devspace commands directly for better experience:"
    echo "  earth worktree create feature/new-ui"
    echo "  mars worktree clean"
    exit 1
  }
  
  # Get the main repository path from a devspace
  get_main_repo() {
    local devspace="$1"
    local devspace_dir="$HOME/devspaces/$devspace"
    local project_link="$devspace_dir/project"
    
    if [ ! -L "$project_link" ]; then
      echo ""
      return
    fi
    
    local project_path=$(readlink "$project_link")
    
    # Check if it's a git repository
    if [ ! -d "$project_path/.git" ]; then
      echo ""
      return
    fi
    
    # Check if it's already a worktree
    if [ -f "$project_path/.git" ]; then
      # It's a worktree, get the main repo
      local gitdir=$(cat "$project_path/.git" | sed 's/gitdir: //')
      echo $(dirname $(dirname "$gitdir"))
    else
      # It's the main repo
      echo "$project_path"
    fi
  }
  
  # Create a worktree for a devspace
  create_worktree() {
    local devspace="$1"
    local branch="$2"
    local devspace_dir="$HOME/devspaces/$devspace"
    local worktree_dir="$devspace_dir/worktrees/$branch"
    
    # Validate devspace
    if [[ ! "$devspace" =~ ^(${validNames})$ ]]; then
      echo -e "''${RED}❌ Invalid devspace: $devspace''${NC}"
      exit 1
    fi
    
    # Get main repository
    local main_repo=$(get_main_repo "$devspace")
    if [ -z "$main_repo" ]; then
      echo -e "''${RED}❌ No git repository linked to $devspace''${NC}"
      echo "First run: $devspace <repo-path>"
      exit 1
    fi
    
    # Check if another devspace is using the same repo
    local repo_name=$(basename "$main_repo")
    local other_devspaces=()
    for space in ${lib.concatStringsSep " " (map (s: s.name) theme.spaces)}; do
      if [ "$space" != "$devspace" ]; then
        local other_repo=$(get_main_repo "$space")
        if [ "$other_repo" = "$main_repo" ]; then
          other_devspaces+=("$space")
        fi
      fi
    done
    
    if [ ''${#other_devspaces[@]} -gt 0 ]; then
      echo -e "''${YELLOW}⚠️  Repository $repo_name is also used by: ''${other_devspaces[*]}''${NC}"
      echo "Creating isolated worktree for $devspace..."
    fi
    
    # Create worktrees directory
    mkdir -p "$devspace_dir/worktrees"
    
    # Check if worktree already exists
    if [ -d "$worktree_dir" ]; then
      echo -e "''${YELLOW}⚠️  Worktree already exists at: $worktree_dir''${NC}"
      read -p "Remove and recreate? (y/N) " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
      fi
      ${git}/bin/git -C "$main_repo" worktree remove "$worktree_dir" --force
    fi
    
    # Create the worktree
    echo -e "''${BLUE}🌳 Creating worktree for branch: $branch''${NC}"
    
    # Check if branch exists
    if ${git}/bin/git -C "$main_repo" show-ref --verify --quiet "refs/heads/$branch"; then
      # Branch exists, create worktree
      ${git}/bin/git -C "$main_repo" worktree add "$worktree_dir" "$branch"
    else
      # Branch doesn't exist, create it
      echo "Creating new branch: $branch"
      ${git}/bin/git -C "$main_repo" worktree add -b "$branch" "$worktree_dir"
    fi
    
    # Update the project symlink to point to the worktree
    rm -f "$devspace_dir/project"
    ln -s "$worktree_dir" "$devspace_dir/project"
    
    echo -e "''${GREEN}✅ Worktree created and linked to $devspace''${NC}"
    echo "Path: $worktree_dir"
    
    # Update tmux session if it exists
    local session_id=$(get_session_id "$devspace")
    local session="devspace-$session_id"
    if ${tmux}/bin/tmux has-session -t "$session" 2>/dev/null; then
      for window in 1 2 3; do
        ${tmux}/bin/tmux send-keys -t "$session:$window" C-c "cd $worktree_dir" Enter
      done
      echo -e "''${GREEN}📍 Updated tmux session working directory''${NC}"
    fi
  }
  
  # List worktrees for a devspace
  list_worktrees() {
    local devspace="$1"
    local devspace_dir="$HOME/devspaces/$devspace"
    
    echo -e "''${BLUE}🌳 Worktrees for $devspace:''${NC}"
    
    if [ ! -d "$devspace_dir/worktrees" ]; then
      echo "  No worktrees"
      return
    fi
    
    local main_repo=$(get_main_repo "$devspace")
    if [ -z "$main_repo" ]; then
      echo "  No repository linked"
      return
    fi
    
    # List all worktrees from git
    ${git}/bin/git -C "$main_repo" worktree list | while read -r line; do
      if [[ "$line" =~ "$devspace_dir/worktrees" ]]; then
        echo "  $line"
      fi
    done
  }
  
  # Clean worktrees for a devspace
  clean_worktree() {
    local devspace="$1"
    local devspace_dir="$HOME/devspaces/$devspace"
    
    # Get current project link
    local current_project=""
    if [ -L "$devspace_dir/project" ]; then
      current_project=$(readlink "$devspace_dir/project")
    fi
    
    # Get main repo
    local main_repo=$(get_main_repo "$devspace")
    if [ -z "$main_repo" ]; then
      echo -e "''${YELLOW}No repository linked to $devspace''${NC}"
      return
    fi
    
    # Find and remove worktrees
    local removed=0
    if [ -d "$devspace_dir/worktrees" ]; then
      for worktree in "$devspace_dir/worktrees"/*; do
        if [ -d "$worktree" ]; then
          local branch=$(basename "$worktree")
          echo "Removing worktree: $branch"
          ${git}/bin/git -C "$main_repo" worktree remove "$worktree" --force 2>/dev/null || true
          removed=$((removed + 1))
        fi
      done
      
      # Clean up empty directory
      rmdir "$devspace_dir/worktrees" 2>/dev/null || true
    fi
    
    if [ $removed -gt 0 ]; then
      echo -e "''${GREEN}✅ Removed $removed worktree(s)''${NC}"
      
      # If the current project was a worktree, relink to main repo
      if [[ "$current_project" =~ "$devspace_dir/worktrees" ]]; then
        rm -f "$devspace_dir/project"
        ln -s "$main_repo" "$devspace_dir/project"
        echo -e "''${GREEN}✅ Relinked $devspace to main repository''${NC}"
        
        # Update tmux session
        local session_id=$(get_session_id "$devspace")
        local session="devspace-$session_id"
        if ${tmux}/bin/tmux has-session -t "$session" 2>/dev/null; then
          for window in 1 2 3; do
            ${tmux}/bin/tmux send-keys -t "$session:$window" C-c "cd $main_repo" Enter
          done
        fi
      fi
    else
      echo "No worktrees to remove"
    fi
  }
  
  # Show status of all devspace worktrees
  show_status() {
    echo -e "''${BLUE}🌳 Devspace Worktree Status''${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    for devspace in ${lib.concatStringsSep " " (map (s: s.name) theme.spaces)}; do
      local devspace_dir="$HOME/devspaces/$devspace"
      local icon=$(${lib.concatStringsSep " " (map (s: ''[ "$devspace" = "${s.name}" ] && echo "${s.icon}"'') theme.spaces)})
      
      echo -e "\n$icon $devspace:"
      
      if [ ! -L "$devspace_dir/project" ]; then
        echo "  📁 No project linked"
        continue
      fi
      
      local project_path=$(readlink "$devspace_dir/project")
      local main_repo=$(get_main_repo "$devspace")
      
      if [ -z "$main_repo" ]; then
        echo "  📁 Linked to: $project_path (not a git repo)"
        continue
      fi
      
      local repo_name=$(basename "$main_repo")
      echo "  📁 Repository: $repo_name"
      
      if [[ "$project_path" =~ "$devspace_dir/worktrees" ]]; then
        local branch=$(basename "$project_path")
        echo -e "  ''${GREEN}🌿 Working in worktree: $branch''${NC}"
      else
        local branch=$(${git}/bin/git -C "$project_path" branch --show-current 2>/dev/null || echo "unknown")
        echo "  🌿 Working in main: $branch"
      fi
      
      # List any other worktrees
      if [ -d "$devspace_dir/worktrees" ]; then
        local count=$(ls -1 "$devspace_dir/worktrees" 2>/dev/null | wc -l)
        if [ $count -gt 0 ]; then
          echo "  📚 $count worktree(s) available"
        fi
      fi
    done
  }
  
  # Main command handling
  case "''${1:-}" in
    create)
      shift
      if [ $# -lt 2 ]; then
        usage
      fi
      create_worktree "$1" "$2"
      ;;
    list)
      shift
      if [ $# -lt 1 ]; then
        usage
      fi
      list_worktrees "$1"
      ;;
    clean)
      shift
      if [ $# -lt 1 ]; then
        usage
      fi
      clean_worktree "$1"
      ;;
    status)
      show_status
      ;;
    *)
      usage
      ;;
  esac
''