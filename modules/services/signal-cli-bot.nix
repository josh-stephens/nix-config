{ config, lib, pkgs, ... }:

let
  cfg = config.services.signal-cli-bot;
  dataDir = "/var/lib/signal-cli";
  configDir = "${config.users.users.signal-cli.home}/.config/signal-cli";
in
{
  options.services.signal-cli-bot = {
    enable = lib.mkEnableOption "Signal CLI bot service";
    
    phoneNumber = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Phone number for Signal account (including country code, e.g., +1234567890)";
    };
    
    phoneNumberFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/signal-bot/phone-number";
      description = "Path to file containing the phone number";
    };
    
    registrationComplete = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether the Signal account has been registered and verified";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create signal-cli user
    users.users.signal-cli = {
      isSystemUser = true;
      group = "signal-cli";
      home = dataDir;
      createHome = true;
    };
    
    users.groups.signal-cli = {};

    # Install signal-cli package
    environment.systemPackages = [ pkgs.signal-cli ];

    # Setup script for initial registration
    system.activationScripts.signal-cli-setup = lib.mkIf (!cfg.registrationComplete) ''
      mkdir -p ${configDir}
      chown -R signal-cli:signal-cli ${dataDir}
      
      if [ -f "${cfg.phoneNumberFile}" ]; then
        PHONE_NUMBER=$(cat ${cfg.phoneNumberFile})
        echo "Signal CLI setup required!"
        echo "Run these commands to register:"
        echo "  sudo -u signal-cli signal-cli -a $PHONE_NUMBER register"
        echo "  sudo -u signal-cli signal-cli -a $PHONE_NUMBER verify CODE"
        echo ""
        echo "Then set services.signal-cli-bot.registrationComplete = true"
      else
        echo "ERROR: Phone number file not found at ${cfg.phoneNumberFile}"
        echo "Create it with: echo '+1234567890' | sudo tee ${cfg.phoneNumberFile}"
      fi
    '';

    # Receive daemon (only runs after registration)
    systemd.services.signal-cli-receive = lib.mkIf cfg.registrationComplete {
      description = "Signal CLI receive daemon";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "simple";
        User = "signal-cli";
        Group = "signal-cli";
        
        ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.signal-cli}/bin/signal-cli -a $(cat ${cfg.phoneNumberFile}) daemon'";
        Restart = "always";
        RestartSec = 10;
        
        # Security hardening
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ dataDir ];
        NoNewPrivileges = true;
      };
    };

    # Helper service for the assistant bot (placeholder for now)
    systemd.services.signal-assistant-bot = lib.mkIf cfg.registrationComplete {
      description = "Signal Assistant Bot";
      after = [ "signal-cli-receive.service" ];
      requires = [ "signal-cli-receive.service" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "simple";
        User = "signal-cli";
        Group = "signal-cli";
        
        # This will be replaced with your actual bot script
        ExecStart = "${pkgs.bash}/bin/bash -c 'echo Bot placeholder - implement me!'";
        
        # Security
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ dataDir ];
      };
    };
  };
}