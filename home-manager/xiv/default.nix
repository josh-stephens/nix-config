{ inputs, lib, config, pkgs, ... }: {
  home.packages = [
    pkgs.xivlauncherRb
    pkgs.TotallyNotCef
    pkgs.fflogs
  ];

  xdg.configFile."xiv" = {
    source = ./xiv;
    recursive = true;
  };

  xdg.desktopEntries.ffxiv = {
    name = "FFXIV";
    genericName = "FFXIV Startup";
    icon = "ffxiv";
    exec = "${config.xdg.configHome}/xiv/start.sh";
    comment = "Start FFXIV";
    categories = [ "Game" ];
  };

  systemd.user.services.TotallyNotCef = {
    Unit = {
      Description = "TotallyNotCef";
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.TotallyNotCef}/bin/TotallyNotCef 'https://siliconexarch.github.io/cactbot/ui/raidboss/raidboss.html?OVERLAY_WS=ws://127.0.0.1:10501/ws' 18283 1 1";
    };
    Install = {
      WantedBy = [ "" ];
    };
  };



}
