{ inputs, lib, config, pkgs, ... }:

{
  # 🪐 Planet Client Commands for Mac
  programs.zsh.initContent = ''
    # 🌌 Planet Development Environment Client Functions
    
    # Helper function to check if we're on Tailscale network
    _check_tailscale() {
      if ! command -v tailscale &> /dev/null; then
        echo "❌ Tailscale not found. Please install Tailscale."
        return 1
      fi
      
      if ! tailscale status &> /dev/null; then
        echo "❌ Tailscale is not running. Please start Tailscale."
        return 1
      fi
      
      if ! tailscale status | grep -q "ultraviolet"; then
        echo "❌ Cannot find ultraviolet on Tailscale network."
        echo "💡 Make sure ultraviolet is online and connected to Tailscale."
        return 1
      fi
      
      return 0
    }
    
    # 🪐 Connect to a planet
    _planet_connect() {
      local planet="$1"
      shift
      local extra_args="$@"
      
      if ! _check_tailscale; then
        return 1
      fi
      
      echo "🚀 Connecting to planet $planet..."
      
      # Use SSH with tmux attach/new logic
      ssh -t ultraviolet "tmux attach-session -t planet-$planet || (echo '❌ Planet $planet not initialized. Run planet-init on ultraviolet first.' && exit 1)" $extra_args
    }
    
    # 🔧 Setup a planet with a project
    _planet_setup() {
      local planet="$1"
      local project="$2"
      
      if ! _check_tailscale; then
        return 1
      fi
      
      if [ -z "$project" ]; then
        echo "📊 Checking $planet setup..."
        ssh ultraviolet "planet-setup $planet"
      else
        echo "🔧 Setting up $planet with project: $project"
        ssh ultraviolet "planet-setup $planet '$project'"
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
      if ! _check_tailscale; then
        return 1
      fi
      
      echo "🌌 Fetching planet status from ultraviolet..."
      ssh ultraviolet planet-status
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
      if ! _check_tailscale; then
        return 1
      fi
      
      echo "🔐 Syncing AWS credentials to ultraviolet..."
      
      # Check if AWS config exists
      if [ ! -d "$HOME/.aws" ]; then
        echo "❌ No AWS configuration found at ~/.aws"
        return 1
      fi
      
      # Sync config files
      echo "📤 Uploading AWS config..."
      rsync -av --delete \
        --include="config" \
        --include="credentials" \
        --include="sso/" \
        --include="sso/cache/" \
        --include="sso/cache/*.json" \
        --exclude="*" \
        "$HOME/.aws/" ultraviolet:.aws/
      
      if [ $? -eq 0 ]; then
        echo "✅ AWS credentials synced successfully!"
        
        # Optionally sync to specific planet
        if [ -n "$1" ]; then
          echo "🪐 Syncing to planet $1..."
          ssh ultraviolet "cp -r ~/.aws ~/planets/$1/.aws"
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