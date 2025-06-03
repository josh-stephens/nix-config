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
    script = ''
      ${pkgs.tmux}/bin/tmux start-server || true
      
      # Create minimal tmux sessions with just planetary names
      for name in mercury venus earth mars jupiter; do
        if ! ${pkgs.tmux}/bin/tmux has-session -t "$name" 2>/dev/null; then
          echo "Creating devspace: $name"
          # Create empty session - user will navigate and create windows as needed
          ${pkgs.tmux}/bin/tmux new-session -d -s "$name"
        else
          echo "Devspace $name already exists"
        fi
      done
      
      echo "All devspaces initialized"
    '';
  };
  
  # Restart devspaces service on rebuild
  system.activationScripts.devspaces = {
    text = ''
      ${pkgs.systemd}/bin/systemctl restart devspaces.service || true
    '';
  };
}