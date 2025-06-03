{ lib, config, pkgs, ... }:

{
  # Devspace client configuration
  programs.zsh.shellAliases = {
    # Direct connection aliases
    mercury = "et ultraviolet:2022 -c 'tmux attach-session -t mercury || tmux new-session -s mercury'";
    venus = "et ultraviolet:2022 -c 'tmux attach-session -t venus || tmux new-session -s venus'";
    earth = "et ultraviolet:2022 -c 'tmux attach-session -t earth || tmux new-session -s earth'";
    mars = "et ultraviolet:2022 -c 'tmux attach-session -t mars || tmux new-session -s mars'";
    jupiter = "et ultraviolet:2022 -c 'tmux attach-session -t jupiter || tmux new-session -s jupiter'";
    
    # Status command to see what's running
    devspace-status = "ssh ultraviolet 'tmux list-sessions 2>/dev/null || echo \"No active sessions\"'";
    
    # Quick aliases for common operations
    ds = "devspace-status";
    dsl = "ssh ultraviolet 'tmux list-sessions -F \"#{session_name}: #{session_windows} windows, created #{session_created_string}\" 2>/dev/null || echo \"No sessions\"'";
  };
  
  # Helper function for devspace information
  programs.zsh.initContent = ''
    devspaces() {
      echo "🌌 Development Spaces"
      echo "━━━━━━━━━━━━━━━━━━━"
      echo
      echo "Available commands:"
      echo "  mercury  - Quick experiments and prototypes"
      echo "  venus    - Personal creative projects"
      echo "  earth    - Primary work project"
      echo "  mars     - Secondary work project"
      echo "  jupiter  - Large personal project"
      echo
      echo "  ds       - Quick status check"
      echo "  dsl      - Detailed session list"
      echo
      echo "Just type the planet name to connect!"
    }
  '';
}