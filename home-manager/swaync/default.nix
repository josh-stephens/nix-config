{ inputs, lib, config, pkgs, ... }:
{
  home.packages = [
    pkgs.unstable.swaynotificationcenter
  ];

  xdg.configFile."swaync" = {
    source = ./swaync;
    recursive = true;
  };

  xdg.dataFile."dbus-1/services/swaync.service".text = ''
    [D-BUS Service]
    Name=org.freedesktop.Notifications
    Exec=${pkgs.swaynotificationcenter}/bin/swaync
    SystemdService=swaync.service
  '';

  systemd.user.services.swaync = {
    Unit = {
      Description = "swaynotificationcenter";
      PartOf = "graphical-session.target";
      After = "graphical-session.target";
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      Type = "dbus";
      BusName = "org.freedesktop.Notifications";
      ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
      ExecReload = "${pkgs.swaynotificationcenter}/bin/swaync-client --reload-config ; ${pkgs.swaynotificationcenter}/bin/swaync-client --reload-css";
      Restart = "on-failure";

    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
