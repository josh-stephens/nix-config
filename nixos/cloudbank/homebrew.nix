let 
  system = "aarch64-darwin";
  user = "joshsymonds";
in { inputs, lib, config, pkgs, ... }: {
  homebrew = {
    enable = true;
    casks = [
      "font-hack-nerd-font"
      "sf-symbols"
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
    };
  };
}
