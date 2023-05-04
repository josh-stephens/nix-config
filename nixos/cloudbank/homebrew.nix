let 
  system = "aarch64-darwin";
  user = "joshsymonds";
in { inputs, lib, config, pkgs, ... }: {
  homebrew = {
    enable = true;
    casks = [
      #"firefox"
      #"signal"
      #"slack"
      #"discord"
    ];
    brews = [
    ];
    masApps = {
      #"Bear" = 1091189122;
      #"WireGuard" = 1451685025;
      #"Tailscale" = 1475387142;
    };
  };
}
