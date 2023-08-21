{ inputs, lib, config, pkgs, ... }: {
  programs.waybar = {
    enable = true;
    package = pkgs.unstable.waybar;
    systemd.enable = true;
    style = (builtins.readFile ./style.css);
    settings = [{
      layer = "bottom";
      position = "top";
      height = 35;
      spacing = 0;

      modules-left = [
        "custom/nixos"
        "hyprland/workspaces"
      ];
      "custom/nixos" = {
        tooltip = false;
        format = "{icon}";
        "format-icons" = {
          "notification" = "<span foreground='red'><sup></sup></span>";
          "dnd-notification" = "<span foreground='red'><sup></sup></span>";
          "none" = "";
          "dnd-none" = "";
          "inhibited-notification" = "<span foreground='red'><sup></sup></span>";
          "inhibited-none" = "";
          "dnd-inhibited-notification" = "<span foreground='red'><sup></sup></span>";
          "dnd-inhibited-none" = "";
        };
        "return-type" = "json";
        "exec-if" = "${pkgs.swaynotificationcenter}/bin/swaync-client";
        "exec" = "${pkgs.swaynotificationcenter}/bin/swaync-client -swb";
        "on-click" = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
        "on-click-right" = "${pkgs.swaynotificationcenter}/bin/swaync-client -d -sw";
        "escape" = true;
      };
      "hyprland/workspaces" = {
        disable-scroll = true;
        all-outputs = true;
        format = "{icon}";
        format-icons = {
          "1" = "";
          "2" = "";
          "3" = "";
          "4" = "";
          "5" = "";
          "6" = "";
          "urgent" = "";
          "focused" = "";
          "default" = "";
        };
      };

      modules-center = [
        "hyprland/window"
      ];

      modules-right = [
        "pulseaudio"
        "network"
        "cpu"
        "memory"
        "clock"
      ];
      pulseaudio = {
        format = "{volume}% {icon} {format_source}";
        format-bluetooth = "{volume}% {icon} {format_source}";
        format-bluetooth-muted = "{icon} {format_source}";
        format-icons = {
          car = "";
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
        on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
      };
      network = {
        format-disconnected = "Disconnected ⚠";
        format-ethernet = "{ipaddr}/{cidr} 󰈀";
        format-linked = "{ifname} (No IP) ";
        format-wifi = "{essid} ({signalStrength}%) ";
      };
      cpu = {
        format = "{usage}% ";
        tooltip = false;
      };
      memory = {
        format = "{}% ";
        tooltip = false;
      };
      clock = {
        format = "{:%H:%M %m-%d-%Y} ";
        tooltip = false;
      };
    }];
  };
}
