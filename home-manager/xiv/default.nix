{ inputs, lib, config, pkgs, ... }: {
  xdg.configFile."xiv" = {
    source = ./xiv;
    recursive = true;
  };

  xiv = pkgs.makeDesktopItem {
    name = "ffxiv";
    desktopName = "FFXIV";
    exec = "${config.xdg.configHome}/xiv/start.sh";
    comment = "Start FFXIV";
    categories = [ "Game" ];
  };

  packages = [
    xiv
  ];
}
