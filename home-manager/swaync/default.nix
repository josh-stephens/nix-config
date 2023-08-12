{ inputs, lib, config, pkgs, ... }:
{
  home.packages = [
    pkgs.unstable.swaynotificationcenter
  ];

  xdg.configFile."swaync" = {
    source = ./swaync;
    recursive = true;
  };

  systemd.user.services.swaync = {
    Unit = {
      Description = "swaynotificationcenter";
      PartOf = "graphical-session.target";
      After = "graphical-session.target";
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      Type = "dbus";
      ExecStart = "${pkgs.swaync}/bin/swaync";
      ExecReload = "${pkgs.swaync}/bin/swaync-client --reload-config ; ${pkgs.swaync}/bin/swaync-client --reload-css";
      Restart = "on-failure";

    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
