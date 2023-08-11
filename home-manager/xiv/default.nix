{ inputs, lib, config, pkgs, ... }: {
  home.packages = [
    pkgs.unstable.xivlauncher
    pkgs.TotallyNotCef
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
    Type = "simple";
    serviceConfig = {
      ExecStart = "${pkgs.TotallyNotCef.bin}/bin/TotallyNotCef 'https://quisquous.github.io/cactbot/ui/raidboss/raidboss.html?OVERLAY_WS=ws://127.0.0.1:10501/ws' 18283 1 1";
    };
    environment = [ "DISPLAY=:0" ];
    wantedBy = [ "" ];
  };
}
