{ config, lib, pkgs, ... }:

{
  # 🪐 Development Spaces Environment - System-level configuration
  # Uses the devspaces package for initialization
  
  # Install the devspaces package which provides devspace-init
  environment.systemPackages = [ pkgs.devspaces ];
  
  # 🤖 Systemd service to initialize development spaces on boot
  systemd.services.devspace-init = {
    description = "Initialize development space tmux sessions";
    after = [ "multi-user.target" "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "joshsymonds";
      ExecStart = "${pkgs.devspaces}/bin/devspace-init";
      StandardOutput = "journal";
      StandardError = "journal";
    };
    
    environment = {
      HOME = "/home/joshsymonds";
      USER = "joshsymonds";
    };
  };
  
  # 🔄 Ensure devspace-init runs after system rebuilds
  system.activationScripts.devspace-init = {
    text = ''
      # Run devspace-init after system activation
      ${pkgs.systemd}/bin/systemctl restart devspace-init.service || true
    '';
    deps = [];
  };
  
  # 📁 Create devspace directories
  systemd.tmpfiles.rules = [
    "d /home/joshsymonds/devspaces 0755 joshsymonds users -"
    "d /home/joshsymonds/devspaces/mercury 0755 joshsymonds users -"
    "d /home/joshsymonds/devspaces/venus 0755 joshsymonds users -"
    "d /home/joshsymonds/devspaces/earth 0755 joshsymonds users -"
    "d /home/joshsymonds/devspaces/mars 0755 joshsymonds users -"
    "d /home/joshsymonds/devspaces/jupiter 0755 joshsymonds users -"
  ];
}
