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
      {
        name = "FelixKratz/formulae/sketchybar";
        restart_service = "changed";
        start_service = true;
      }
      {
        name = "koekeishiya/formulae/yabai";
        restart_service = "changed";
        start_service = true;
      }
      {
        name = "koekeishiya/formulae/skhd";
        restart_service = "changed";
        start_service = true;
      }
    ];
    masApps = {
      #"Bear" = 1091189122;
      #"WireGuard" = 1451685025;
      #"Tailscale" = 1475387142;
    };
  };
}
