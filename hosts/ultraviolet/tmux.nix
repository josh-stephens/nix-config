{ config, lib, pkgs, ... }:

{
  # 🪐 Planet Development Environment - System-level configuration
  # This module provides system-level services for the planet tmux environment
  # The actual tmux configuration and scripts are in home-manager/tmux
  
  # 🤖 Systemd service to initialize planets on boot
  systemd.services.planet-init = {
    description = "Initialize planet tmux sessions";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "joshsymonds";
      # The planet-init command is provided by home-manager tmux module
      ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 5 && /home/joshsymonds/.nix-profile/bin/planet-init'";
    };
  };
  
  # 🔄 Ensure planet-init runs after system rebuilds
  system.activationScripts.planet-init = {
    text = ''
      # Run planet-init after system activation
      ${pkgs.systemd}/bin/systemctl restart planet-init.service || true
    '';
    deps = [];
  };
  
  # 📁 Create planet directories
  systemd.tmpfiles.rules = [
    "d /home/joshsymonds/planets 0755 joshsymonds users -"
    "d /home/joshsymonds/planets/mercury 0755 joshsymonds users -"
    "d /home/joshsymonds/planets/venus 0755 joshsymonds users -"
    "d /home/joshsymonds/planets/earth 0755 joshsymonds users -"
    "d /home/joshsymonds/planets/mars 0755 joshsymonds users -"
    "d /home/joshsymonds/planets/jupiter 0755 joshsymonds users -"
  ];
}