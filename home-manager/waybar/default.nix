{ inputs, lib, config, pkgs, ... }: {
  programs.waybar = {
    enable = true;
    package = pkgs.unstable.waybar;
    systemd.enable = true;
    style = (builtins.readFile ./style.css);
    settings = [{
      layer = "bottom";
      position = "top";
      height = 40;
      spacing = 4;
      tray = { spacing = 10; };
      modules-left = [ "wlr/workspaces" ];
      modules-center = [ "hyprland/window" ];
      modules-right = [
        "pulseaudio"
        "network"
        "cpu"
        "memory"
        "temperature"
        "clock"
        "custom/notification"
      ];
      "wlr/workspaces" = {
        disable-scroll = true;
        all-outputs = true;
        format = "{icon}";
        format-icons = {
          "1" = " ";
          "2" = " ";
          "3" = " ";
          "4" = " ";
          "5" = " ";
          "6" = " ";
          "urgent" = " ";
          "focused" = " ";
          "default" = " ";
        };
      };
      clock = {
        format = "  {:%I:%M %p}";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        format-alt = "{:%Y-%m-%d}";
      };
      cpu = {
        format = "{usage}%  ";
        tooltip = false;
      };
      memory = { format = "{}%  "; };
      network = {
        format-alt = "{ipaddr}/{cidr}";
        format-disconnected = "Disconnected ⚠ ";
        format-ethernet = "{ipaddr}/{cidr} 󰈀 ";
        format-linked = "{ifname} (No IP) ";
        format-wifi = "{essid} ({signalStrength}%)  ";
      };
      pulseaudio = {
        format = "{volume}% {icon} {format_source}";
        format-bluetooth = "{volume}% {icon} {format_source}";
        format-bluetooth-muted = " {icon} {format_source}";
        format-icons = {
          car = " ";
          default = [ "" "" " " ];
          handsfree = "";
          headphones = " ";
          headset = "";
          phone = " ";
          portable = " ";
        };
        format-muted = " {format_source}";
        format-source = "{volume}% ";
        format-source-muted = " ";
        on-click = "/etc/profiles/per-user/joshsymonds/bin/pavucontrol";
      };
      temperature = {
        critical-threshold = 80;
        format = "{temperatureC}°C {icon}";
        format-icons = [ "" "" "" ];
      };
      "custom/notification" = {
        tooltip = false;
        format = "{icon}";
        "format-icons" = {
          "notification" = "<span foreground='red'><sup></sup></span>";
          "dnd-notification" = "<span foreground='red'><sup></sup></span>";
          "none" = " ";
          "dnd-none" = " ";
          "inhibited-notification" = " <span foreground='red'><sup></sup></span>";
          "inhibited-none" = " ";
          "dnd-inhibited-notification" = " <span foreground='red'><sup></sup></span>";
          "dnd-inhibited-none" = " ";
        };
        "return-type" = "json";
        "exec-if" = "${pkgs.swaynotificationcenter}/bin/swaync-client";
        "exec" = "${pkgs.swaynotificationcenter}/bin/swaync-client -swb";
        "on-click" = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
        "on-click-right" = "${pkgs.swaynotificationcenter}/bin/swaync-client -d -sw";
        "escape" = true;
      };
    }];
  };
}
