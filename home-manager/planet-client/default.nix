{ inputs, lib, config, pkgs, ... }:

{
  # 🪐 Planet Client Commands for Mac
  programs.zsh.initContent = ''
    # 🌌 Planet Development Environment Client Functions
    
    # Note: This module depends on ssh-hosts module for _smart_ssh function
    # The ultraviolet() function is defined there
    
    # 🪐 Connect to a planet
    _planet_connect() {
      local planet="$1"
      shift
      local extra_args="$@"
      
      # Use the smart SSH function to connect, then run tmux command
      echo "🪐 Connecting to planet $planet..."
      _smart_ssh ultraviolet -t "tmux attach-session -t planet-$planet || (echo '❌ Planet $planet not initialized. Run planet-init on ultraviolet first.' && exit 1)" $extra_args
    }
    
    # 🔧 Setup a planet with a project
    _planet_setup() {
      local planet="$1"
      local project="$2"
      
      if [ -z "$project" ]; then
        echo "📊 Checking $planet setup..."
        _smart_ssh ultraviolet "planet-setup $planet"
      else
        echo "🔧 Setting up $planet with project: $project"
        _smart_ssh ultraviolet "planet-setup $planet '$project'"
      fi
    }
    
    # 🌍 Planet connection functions
    mercury() {
      _planet_connect mercury "$@"
    }
    
    venus() {
      _planet_connect venus "$@"
    }
    
    earth() {
      _planet_connect earth "$@"
    }
    
    mars() {
      _planet_connect mars "$@"
    }
    
    jupiter() {
      _planet_connect jupiter "$@"
    }
    
    # 📊 Status command
    planet-status() {
      echo "🌌 Fetching planet status from ultraviolet..."
      _smart_ssh ultraviolet planet-status
    }
    
    # 🔧 Setup commands from Mac
    planet-setup() {
      if [ $# -lt 1 ]; then
        echo "Usage: planet-setup <planet> [project-path-on-ultraviolet]"
        echo "  planet-setup earth ~/projects/work/main-app"
        echo "  planet-setup mars"
        return 1
      fi
      
      _planet_setup "$@"
    }
    
    # 🔄 AWS credential sync
    planet-sync-aws() {
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
        
        # Optionally sync to specific planet
        if [ -n "$1" ]; then
          echo "🪐 Syncing to planet $1..."
          _smart_ssh ultraviolet "cp -r ~/.aws ~/planets/$1/.aws"
        fi
      else
        echo "❌ Failed to sync AWS credentials"
        return 1
      fi
    }
    
    # 🚀 Quick connect with project setup
    planet() {
      case "$1" in
        status)
          planet-status
          ;;
        setup)
          shift
          planet-setup "$@"
          ;;
        sync-aws)
          shift
          planet-sync-aws "$@"
          ;;
        mercury|venus|earth|mars|jupiter)
          _planet_connect "$@"
          ;;
        *)
          echo "🌌 Planet Development Environment"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo
          echo "Usage:"
          echo "  mercury|venus|earth|mars|jupiter  - Connect to planet"
          echo "  planet status                     - Show all planets status"
          echo "  planet setup <name> [path]        - Setup planet project"
          echo "  planet sync-aws [planet]          - Sync AWS credentials"
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
    alias ps="planet status"
    alias psa="planet sync-aws"
  '';
  
  # 🔧 Additional tools that might be useful
  home.packages = with pkgs; [
    rsync
  ];
}