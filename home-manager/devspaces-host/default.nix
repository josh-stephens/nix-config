{ lib, config, pkgs, ... }:

{
  # Devspace host configuration - for running ON ultraviolet
  programs.zsh.shellAliases = {
    # Local tmux session aliases - attach or create with TMUX_DEVSPACE set
    mercury = "tmux attach-session -t mercury 2>/dev/null || (tmux new-session -d -s mercury && tmux set-environment -t mercury TMUX_DEVSPACE mercury && tmux attach-session -t mercury)";
    venus = "tmux attach-session -t venus 2>/dev/null || (tmux new-session -d -s venus && tmux set-environment -t venus TMUX_DEVSPACE venus && tmux attach-session -t venus)";
    earth = "tmux attach-session -t earth 2>/dev/null || (tmux new-session -d -s earth && tmux set-environment -t earth TMUX_DEVSPACE earth && tmux attach-session -t earth)";
    mars = "tmux attach-session -t mars 2>/dev/null || (tmux new-session -d -s mars && tmux set-environment -t mars TMUX_DEVSPACE mars && tmux attach-session -t mars)";
    jupiter = "tmux attach-session -t jupiter 2>/dev/null || (tmux new-session -d -s jupiter && tmux set-environment -t jupiter TMUX_DEVSPACE jupiter && tmux attach-session -t jupiter)";

    # Status command to see what's running locally
    devspace-status = "tmux list-sessions 2>/dev/null || echo \"No active sessions\"";

    # Quick aliases for common operations
    ds = "devspace-status";
    dsl = "tmux list-sessions -F \"#{session_name}: #{session_windows} windows, created #{session_created_string}\" 2>/dev/null || echo \"No sessions\"";
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
