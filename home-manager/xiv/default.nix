{ inputs, lib, config, pkgs, ... }: {
  xdg.configFile."xiv" = {
    source = ./xiv;
    recursive = true;
  };

  home.packages = [
    pkgs.hudkit
  ];

  xdg.desktopEntries.ffxiv = {
    name = "FFXIV";
    genericName = "FFXIV Startup";
    icon="ffxiv";
    exec = "${config.xdg.configHome}/xiv/start.sh";
    comment = "Start FFXIV";
    categories = [ "Game" ];
  };
}
