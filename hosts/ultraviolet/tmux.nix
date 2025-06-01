{ config, lib, pkgs, ... }:

{
  # 🪐 Development Spaces Environment - System-level configuration
  # Uses the devspaces package for initialization
  
  # Install the devspaces package which provides devspace-init
  environment.systemPackages = [ pkgs.devspaces ];
  
  # 🤖 Systemd service to restore/initialize development spaces on boot
  systemd.services.devspace-restore = {
    description = "Restore development space tmux sessions";
    after = [ "multi-user.target" "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "joshsymonds";
      ExecStart = "${pkgs.devspaces}/bin/devspace-restore";
      # Save state before stopping
      ExecStop = "${pkgs.devspaces}/bin/save_session_state";
      StandardOutput = "journal";
      StandardError = "journal";
      # Allow service to succeed even if restore has issues
      SuccessExitStatus = "0 1";
      # Restart on failure with delay
      Restart = "on-failure";
      RestartSec = "5s";
      StartLimitBurst = 3;
    };
    
    environment = {
      HOME = "/home/joshsymonds";
      USER = "joshsymonds";
      PATH = "${pkgs.tmux}/bin:${pkgs.coreutils}/bin:${pkgs.bash}/bin";
    };
  };
  
  # 🔄 Ensure devspace-restore runs after system rebuilds
  system.activationScripts.devspace-restore = {
    text = ''
      # Save current state before activation
      if ${pkgs.systemd}/bin/systemctl is-active --quiet devspace-restore.service; then
        ${pkgs.sudo}/bin/sudo -u joshsymonds ${pkgs.devspaces}/bin/save_session_state || true
      fi
      
      # Run devspace-restore after system activation
      ${pkgs.systemd}/bin/systemctl restart devspace-restore.service || true
    '';
    deps = [];
  };
  
  # 💾 Save tmux state periodically and on shutdown
  systemd.timers.devspace-save-state = {
    description = "Periodically save devspace tmux state";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "30min";
      Unit = "devspace-save-state.service";
    };
  };
  
  systemd.services.devspace-save-state = {
    description = "Save devspace tmux state";
    serviceConfig = {
      Type = "oneshot";
      User = "joshsymonds";
      ExecStart = "${pkgs.devspaces}/bin/save_session_state";
    };
    environment = {
      HOME = "/home/joshsymonds";
      USER = "joshsymonds";
    };
  };
  
  # 📁 Create devspace directories and state directory
  systemd.tmpfiles.rules = let
    theme = import ../../pkgs/devspaces/theme.nix;
    devspaceRules = map (space: 
      "d /home/joshsymonds/devspaces/${space.name} 0755 joshsymonds users -"
    ) theme.spaces;
  in [
    "d /home/joshsymonds/devspaces 0755 joshsymonds users -"
    "d /home/joshsymonds/.local/state/tmux-devspaces 0755 joshsymonds users -"
  ] ++ devspaceRules;
}
