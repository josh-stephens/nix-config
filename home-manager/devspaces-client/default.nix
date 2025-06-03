{ inputs, lib, config, pkgs, ... }:

let
  # Import the theme from the devspaces package
  theme = import ../../pkgs/devspaces/theme.nix;
  spaceNames = lib.concatStringsSep " " (map (s: s.name) theme.spaces);
  
  # Generate connection message lookup
  connectMessages = lib.listToAttrs (map (s: { name = s.name; value = s.connectMessage; }) theme.spaces);
  
  # Generate devspace ID lookup
  devspaceIds = lib.listToAttrs (map (s: { name = s.name; value = toString s.id; }) theme.spaces);
in

{
  # 🚀 Devspaces Client Commands for Mac
  programs.zsh.initContent = ''
    # 🌌 Development Spaces Client Functions
    
    # Note: This module depends on ssh-hosts module for host connection functions
    # The ultraviolet() function is defined there
    
    # 🚀 Connect to a devspace
    _devspace_connect() {
      local devspace="$1"
      shift
      local extra_args="$@"
      
      # Use the smart SSH function to connect, then run tmux command
      # Theme-aware connection message from theme configuration
      case "$devspace" in
        ${lib.concatStringsSep "\n        " (map (s: ''${s.name}) echo "${s.connectMessage}" ;;'') theme.spaces)}
        *) echo "🚀 Connecting to devspace $devspace..." ;;
      esac
      # Get the devspace ID from theme
      local devspace_id=""
      case "$devspace" in
        ${lib.concatStringsSep "\n        " (map (s: ''${s.name}) devspace_id="${toString s.id}" ;;'') theme.spaces)}
      esac
      
      # Single ET connection that handles everything
      echo "⚡ Connecting with Eternal Terminal..."
      # First, let's test if tmux works at all through ET
      echo "🔍 Testing tmux through ET..."
      et ultraviolet:2022 -c "tmux -V && tmux list-sessions 2>&1 || echo 'tmux check failed'"
      
      # Now try the actual connection
      echo "🚀 Connecting to devspace..."
      et ultraviolet:2022 -e -c "$devspace connect"
    }
    
    # 🔧 Setup a devspace with a project
    _devspace_setup() {
      local devspace="$1"
      local project="$2"
      
      if [ -z "$project" ]; then
        echo "📊 Checking $devspace setup..."
        et ultraviolet:2022 -c "devspace-setup $devspace"
      else
        echo "🔧 Setting up $devspace with project: $project"
        et ultraviolet:2022 -c "devspace-setup $devspace '$project'"
      fi
    }
    
    # 🌍 Dynamically create devspace connection functions
    # Generated from the theme configuration
    DEVSPACE_NAMES=(${spaceNames})
    
    for devspace in "''${DEVSPACE_NAMES[@]}"; do
      eval "$devspace() { _devspace_connect $devspace \"\$@\"; }"
    done
    
    # 📊 Status command
    devspace-status() {
      echo "🌌 Fetching devspace status from ultraviolet..."
      et ultraviolet:2022 -c "devspace-status"
    }
    
    # 🔧 Setup commands from Mac (legacy - use earth setup instead)
    devspace-setup() {
      if [ $# -lt 1 ]; then
        echo "Note: This is a legacy command. Use the devspace shortcuts instead:"
        echo "  earth setup ~/projects/work/main-app"
        echo "  mars status"
        echo ""
        echo "Legacy usage: devspace-setup <devspace> [project-path-on-ultraviolet]"
        return 1
      fi
      
      _devspace_setup "$@"
    }
    
    # 🔄 AWS credential sync
    devspace-sync-aws() {
      echo "🔐 Syncing AWS credentials to ultraviolet..."
      
      # Check if AWS config exists
      if [ ! -d "$HOME/.aws" ]; then
        echo "❌ No AWS configuration found at ~/.aws"
        return 1
      fi
      
      # Get the target host using smart SSH logic
      local target_host
      if command -v tailscale &> /dev/null && tailscale status 2>/dev/null | grep -q "ultraviolet"; then
        if ping -c 1 -W 1 "ultraviolet" &> /dev/null; then
          target_host="ultraviolet"
        fi
      fi
      
      if [ -z "$target_host" ] && ping -c 1 -W 1 "172.31.0.200" &> /dev/null; then
        target_host="172.31.0.200"
      fi
      
      if [ -z "$target_host" ]; then
        echo "❌ Cannot reach ultraviolet"
        return 1
      fi
      
      # Sync config files
      echo "📤 Uploading AWS config to $target_host..."
      rsync -av --delete \
        --include="config" \
        --include="credentials" \
        --include="sso/" \
        --include="sso/cache/" \
        --include="sso/cache/*.json" \
        --exclude="*" \
        "$HOME/.aws/" "$target_host:.aws/"
      
      if [ $? -eq 0 ]; then
        echo "✅ AWS credentials synced successfully!"
        
        # Optionally sync to specific devspace
        if [ -n "$1" ]; then
          echo "🔄 Syncing to devspace $1..."
          ultraviolet cp -r ~/.aws ~/devspaces/$1/.aws
        fi
      else
        echo "❌ Failed to sync AWS credentials"
        return 1
      fi
    }
    
    # 🚀 Quick connect with project setup
    devspace() {
      case "$1" in
        status)
          devspace-status
          ;;
        setup)
          shift
          devspace-setup "$@"
          ;;
        sync-aws)
          shift
          devspace-sync-aws "$@"
          ;;
        ${lib.concatStringsSep "|" (map (s: s.name) theme.spaces)})
          _devspace_connect "$@"
          ;;
        *)
          echo "🌌 Development Spaces Environment"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo
          echo "Usage:"
          echo "  mercury|venus|earth|mars|jupiter  - Connect to devspace"
          echo "  devspace status                   - Show all devspaces status"
          echo "  devspace setup <name> [path]      - Setup devspace project"
          echo "  devspace sync-aws [devspace]      - Sync AWS credentials"
          echo
          echo "Quick connect:"
          echo "  earth     - Connect to primary work project"
          echo "  mars      - Connect to secondary work project"
          echo "  venus     - Connect to personal creative project"
          echo "  jupiter   - Connect to large personal project"
          echo "  mercury   - Connect to experiments"
          ;;
      esac
    }
    
    # 📱 Mobile-friendly aliases (shorter to type)
    alias ds="devspace status"
    alias dsa="devspace sync-aws"
    
    # 🌳 Worktree management aliases
    alias dwt="devspace-worktree"
    alias dwtc="devspace-worktree create"
    alias dwts="devspace-worktree status"
    alias dwtl="devspace-worktree list"
  '';
  
  # 🔧 Additional tools that might be useful
  home.packages = with pkgs; [
    rsync
  ];
}