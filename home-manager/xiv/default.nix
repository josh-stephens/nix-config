{ inputs, lib, config, pkgs, ... }: {
  home.packages = [ pkgs.unstable.xivlauncher ];

  xdg.configFile."xiv" = {
    source = ./xiv;
    recursive = true;
  };

  xdg.desktopEntries.ffxiv = {
    name = "FFXIV";
    genericName = "FFXIV Startup";
    icon="ffxiv";
    exec = "${config.xdg.configHome}/xiv/start.sh";
    comment = "Start FFXIV";
    categories = [ "Game" ];
  };
}
