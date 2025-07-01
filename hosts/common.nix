{ inputs, outputs, lib, config, pkgs, ... }: {
  # Nix store management - prevent disk space issues
  nix = {
    # Automatic garbage collection
    gc = {
      automatic = true;
      dates = "weekly";  # Run every Sunday at midnight
      options = "--delete-older-than 14d";  # Keep derivations for 2 weeks
    };
    
    # Automatic store optimization (hard-linking identical files)
    optimise.automatic = true;
    
    settings = {
      # Trigger GC when disk space is low
      min-free = "${toString (10 * 1024 * 1024 * 1024)}"; # 10GB free space minimum
      max-free = "${toString (50 * 1024 * 1024 * 1024)}"; # Clean up to 50GB when triggered
    };
  };

  fileSystems = {
    "/mnt/video" = {
      device = "172.31.0.100:/volume1/video";
      fsType = "nfs";
    };
    "/mnt/music" = {
      device = "172.31.0.100:/volume1/music";
      fsType = "nfs";
    };
    "/mnt/books" = {
      device = "172.31.0.100:/volume1/books";
      fsType = "nfs";
    };
  };

  # Enable Eternal Terminal for low-latency persistent connections
  services.eternal-terminal = {
    enable = true;
    port = 2022;
  };

  # Open firewall for ET
  networking.firewall.allowedTCPPorts = [ 2022 ];

}
