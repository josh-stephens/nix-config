{ inputs, lib, config, pkgs, ... }:

{
  # 🌐 Smart SSH Host Commands for Mac
  programs.zsh.initContent = ''
    # Configuration for all hosts
    declare -A HOST_IPS
    declare -A HOST_TAILSCALE
    
    # Define hosts with their local IPs and Tailscale names
    HOST_IPS[ultraviolet]="172.31.0.200"
    HOST_TAILSCALE[ultraviolet]="ultraviolet"
    
    HOST_IPS[bluedesert]="172.31.0.201"
    HOST_TAILSCALE[bluedesert]="bluedesert"
    
    HOST_IPS[echelon]="192.168.1.200"  # Different subnet
    HOST_TAILSCALE[echelon]="echelon"
    
    HOST_IPS[cloudbank]="127.0.0.1"  # Local machine
    HOST_TAILSCALE[cloudbank]=""  # Not on Tailscale
    
    # Cache for Tailscale status (5 minute TTL)
    TAILSCALE_STATUS_CACHE=""
    TAILSCALE_STATUS_TIME=0
    
    # Fast Tailscale status check with caching
    _get_tailscale_status() {
      local current_time=$(date +%s)
      local cache_age=$((current_time - TAILSCALE_STATUS_TIME))
      
      # Use cache if less than 5 minutes old (300 seconds)
      if [ $cache_age -lt 300 ] && [ -n "$TAILSCALE_STATUS_CACHE" ]; then
        echo "$TAILSCALE_STATUS_CACHE"
        return 0
      fi
      
      # Check if Tailscale is available and running
      if command -v tailscale &> /dev/null && tailscale status --json &> /dev/null; then
        TAILSCALE_STATUS_CACHE=$(tailscale status --peers=false 2>/dev/null | grep -E "^\S+\s+" | awk '{print $1}')
        TAILSCALE_STATUS_TIME=$current_time
        echo "$TAILSCALE_STATUS_CACHE"
        return 0
      fi
      
      return 1
    }
    
    # Smart host connection function - ET by default, SSH fallback
    _smart_connect() {
      local hostname="$1"
      shift
      local use_ssh=0
      local extra_args=()
      
      # Parse arguments
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --ssh)
            use_ssh=1
            shift
            ;;
          *)
            extra_args+=("$1")
            shift
            ;;
        esac
      done
      
      # Check if host is configured
      if [ -z "''${HOST_IPS[$hostname]}" ]; then
        echo "❌ Unknown host: $hostname"
        echo "💡 Available hosts: ''${(k)HOST_IPS[@]}"
        return 1
      fi
      
      local local_ip="''${HOST_IPS[$hostname]}"
      local tailscale_name="''${HOST_TAILSCALE[$hostname]}"
      local target_host=""
      
      # Special case for localhost
      if [ "$hostname" = "cloudbank" ] || [ "$local_ip" = "127.0.0.1" ]; then
        echo "🏠 This is the local machine!"
        return 0
      fi
      
      # Try Tailscale first if configured for this host
      if [ -n "$tailscale_name" ]; then
        local tailscale_hosts
        if tailscale_hosts=$(_get_tailscale_status); then
          if echo "$tailscale_hosts" | grep -q "^$tailscale_name$"; then
            # Quick ping test with very short timeout
            if ping -c 1 -W 1 "$tailscale_name" &> /dev/null; then
              target_host="$tailscale_name"
              if [ $use_ssh -eq 1 ]; then
                echo "🔒 Connecting to $hostname via Tailscale (SSH)..."
              else
                echo "⚡ Connecting to $hostname via Tailscale (ET)..."
              fi
            fi
          fi
        fi
      fi
      
      # Fall back to local network if Tailscale didn't work
      if [ -z "$target_host" ]; then
        # Quick ping test for local network
        if ping -c 1 -W 1 "$local_ip" &> /dev/null; then
          target_host="$local_ip"
          if [ $use_ssh -eq 1 ]; then
            echo "🏠 Connecting to $hostname via local network (SSH)..."
          else
            echo "⚡ Connecting to $hostname via local network (ET)..."
          fi
        else
          echo "❌ Cannot reach $hostname via Tailscale or local network ($local_ip)"
          echo "💡 Make sure you're on the local network or connected to Tailscale"
          return 1
        fi
      fi
      
      # Try ET first, fall back to SSH if it fails
      if [ $use_ssh -eq 0 ]; then
        if command -v et &> /dev/null; then
          # If there are extra args, assume they're a command to run
          if [ ''${#extra_args[@]} -gt 0 ]; then
            # Run command via ET - ET takes command as trailing arguments
            et "$target_host:2022" "''${extra_args[@]}" 2>/dev/null && return 0
          else
            # Just connect
            et "$target_host:2022" 2>/dev/null && return 0
          fi
          echo "⚠️  ET connection failed, falling back to SSH..."
        fi
      fi
      
      # Use SSH (with kitten for clipboard integration)
      if [ ''${#extra_args[@]} -gt 0 ]; then
        # Run command via SSH
        kitten ssh "$target_host" "''${extra_args[*]}"
      else
        # Just connect
        kitten ssh "$target_host"
      fi
    }
    
    # Create command for each host (ET by default, SSH with --ssh flag)
    ultraviolet() {
      _smart_connect ultraviolet "$@"
    }
    
    ultraviolet-ssh() {
      _smart_connect ultraviolet --ssh "$@"
    }
    
    bluedesert() {
      _smart_connect bluedesert "$@"
    }
    
    bluedesert-ssh() {
      _smart_connect bluedesert --ssh "$@"
    }
    
    echelon() {
      _smart_connect echelon "$@"
    }
    
    echelon-ssh() {
      _smart_connect echelon --ssh "$@"
    }
    
    cloudbank() {
      _smart_connect cloudbank "$@"
    }
    
    # Universal 'ssh-to' command
    ssh-to() {
      if [ $# -lt 1 ]; then
        echo "Usage: ssh-to <hostname> [args]"
        echo "Available hosts: ''${(k)HOST_IPS[@]}"
        echo "Note: Uses ET by default, add --ssh for regular SSH"
        return 1
      fi
      _smart_connect "$@"
    }
    
    # List all configured hosts
    ssh-hosts() {
      echo "🌐 Configured SSH Hosts"
      echo "━━━━━━━━━━━━━━━━━━━━━"
      echo
      
      local tailscale_hosts
      tailscale_hosts=$(_get_tailscale_status 2>/dev/null || echo "")
      
      for host in ''${(k)HOST_IPS[@]}; do
        local ip="''${HOST_IPS[$host]}"
        local ts_name="''${HOST_TAILSCALE[$host]}"
        local status="❓"
        local via=""
        
        # Check connectivity
        if [ "$host" = "cloudbank" ] || [ "$ip" = "127.0.0.1" ]; then
          status="🏠"
          via="local"
        elif [ -n "$ts_name" ] && echo "$tailscale_hosts" | grep -q "^$ts_name$"; then
          if ping -c 1 -W 1 "$ts_name" &> /dev/null; then
            status="🔒"
            via="tailscale"
          fi
        fi
        
        if [ "$via" = "" ] && ping -c 1 -W 1 "$ip" &> /dev/null; then
          status="🌐"
          via="local network"
        elif [ "$via" = "" ]; then
          status="❌"
          via="unreachable"
        fi
        
        printf "%-12s %s %-15s %s\n" "$host" "$status" "$ip" "($via)"
      done
      
      echo
      echo "Legend: 🏠 local | 🔒 tailscale | 🌐 local network | ❌ unreachable"
      echo
      echo "Connection types:"
      echo "  host         - ET with SSH fallback"
      echo "  host-ssh     - Force SSH"
    }
    
    # Convenient aliases
    alias uv="ultraviolet"
    alias uv-ssh="ultraviolet-ssh"
    alias bd="bluedesert"
    alias bd-ssh="bluedesert-ssh"
  '';
}