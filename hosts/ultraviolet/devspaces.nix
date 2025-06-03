{ config, lib, pkgs, ... }:

{
  # Devspace tmux sessions with planetary names
  systemd.services.devspaces = {
    description = "Initialize devspace tmux sessions";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "joshsymonds";
    };
    script = let
      tmux = "${pkgs.tmux}/bin/tmux";
    in ''
      ${tmux} start-server || true
      
      # Create minimal tmux sessions with just planetary names
      for name in mercury venus earth mars jupiter; do
        if ! ${tmux} has-session -t "$name" 2>/dev/null; then
          echo "Creating devspace: $name"
          # Create empty session with TMUX_DEVSPACE environment variable
          ${tmux} new-session -d -s "$name" \
            -e TMUX_DEVSPACE="$name"
          # Make it global so new windows inherit it
          ${tmux} set-environment -t "$name" -g TMUX_DEVSPACE "$name"
        else
          echo "Devspace $name already exists"
        fi
      done
      
      echo "All devspaces initialized"
    '';
  };
  
}