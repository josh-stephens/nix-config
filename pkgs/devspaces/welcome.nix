{ lib, writeScriptBin, bash, toilet, coreutils }:

let
  theme = import ./theme.nix;
in
writeScriptBin "devspace-welcome" ''
  #!${bash}/bin/bash
  # 🎨 Display a nice welcome message for devspaces
  
  set -euo pipefail
  
  # Get devspace from environment or argument
  DEVSPACE="''${1:-''${TMUX_DEVSPACE:-}}"
  
  if [ -z "$DEVSPACE" ]; then
    echo "❌ No devspace specified"
    exit 1
  fi
  
  # Get devspace configuration
  case "$DEVSPACE" in
    ${lib.concatStringsSep "\n    " (map (s: ''
    ${s.name})
      color="${s.color}"
      icon="${s.icon}"
      description="${s.description}"
      ;;'') theme.spaces)}
    *)
      echo "❌ Unknown devspace: $DEVSPACE"
      exit 1
      ;;
  esac
  
  # Clear screen for a clean display
  clear
  
  # Display colorful space-themed banner
  # Using toilet for ASCII art (redirect stderr to suppress Ruby warnings)
  ${toilet}/bin/toilet -f pagga -F border --gay "$DEVSPACE" 2>/dev/null
  
  # Display planet ASCII art based on devspace
  case "$DEVSPACE" in
    mercury)
      echo "    ·   "
      echo "   ⚪   "
      echo "    ·   "
      ;;
    venus)
      echo "   ✧･ﾟ  "
      echo "  🟡   "
      echo "   ･ﾟ✧  "
      ;;
    earth)
      echo "   ✦   "
      echo "  🌍   "
      echo "   ✦   "
      ;;
    mars)
      echo "   ∘   "
      echo "  🔴   "
      echo "   ∘   "
      ;;
    jupiter)
      echo "  ･ﾟ✧*:･ﾟ"
      echo "   🟠   "
      echo "  ･ﾟ✧*:･ﾟ"
      ;;
  esac
  
  echo
  # Colorful divider - suppress Ruby warnings from toilet
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" 2>/dev/null
  echo "$icon Devspace: $DEVSPACE"
  echo "📝 Purpose: $description"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" 2>/dev/null
  echo
  
  # Check if project is linked
  DEVSPACE_DIR="$HOME/devspaces/$DEVSPACE"
  if [ -L "$DEVSPACE_DIR/project" ] && [ -e "$DEVSPACE_DIR/project" ]; then
    PROJECT_PATH=$(readlink "$DEVSPACE_DIR/project")
    PROJECT_NAME=$(basename "$PROJECT_PATH")
    
    echo "📁 Project: $PROJECT_NAME"
    echo "📍 Path: $PROJECT_PATH"
    
    # Show git info if it's a git repo
    if [ -d "$PROJECT_PATH/.git" ]; then
      cd "$PROJECT_PATH"
      BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
      echo "🌿 Branch: $BRANCH"
      
      # Show brief status
      CHANGES=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
      if [ "$CHANGES" -gt 0 ]; then
        echo "📝 Changes: $CHANGES uncommitted"
      else
        echo "✅ Status: Clean working tree"
      fi
    fi
    
    echo
    echo "💡 Commands:"
    echo "   claude         - Start Claude Code in this project"
    echo "   $DEVSPACE status    - Show current configuration"
    echo "   $DEVSPACE worktree  - Manage git worktrees"
  else
    echo "⚡ This devspace is not initialized yet!"
    echo
    echo "To set up this devspace, run:"
    echo "   $DEVSPACE /path/to/project"
    echo
    echo "Examples:"
    echo "   $DEVSPACE ~/Work/my-project"
    echo "   $DEVSPACE .                  # Use current directory"
    echo
    echo "Other commands:"
    echo "   $DEVSPACE status              # Show current configuration"
    echo "   $DEVSPACE worktree create feature/xyz  # Create a git worktree"
  fi
  
  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" 2>/dev/null
  
  # If project is linked, cd to it
  if [ -L "$DEVSPACE_DIR/project" ] && [ -e "$DEVSPACE_DIR/project" ]; then
    cd "$PROJECT_PATH"
    echo
    echo "📍 Working directory: $(pwd)"
  fi
''