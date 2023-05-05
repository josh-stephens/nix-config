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
    taps = [
      "FelixKratz/formulae"
      "koekeishiya/formulae"
    ];
    brews = [
      {
        name = "sketchybar";
        restart_service = "changed";
        start_service = true;
        args = [ "HEAD" ];
      }
      "yabai"
      "skhd"
    ];
    masApps = {
      #"Bear" = 1091189122;
      #"WireGuard" = 1451685025;
      #"Tailscale" = 1475387142;
    };
  };
}
