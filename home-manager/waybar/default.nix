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

      modules-left = [
        "custom/nixos"
        "custom/separator1"
        "hyprland/workspaces"
      ];
      "custom/nixos" = {
        format = " ";
        tooltip = false;
      };
      "custom/separator1" = {
        format = "";
        tooltip = false;
      };
      "hyprland/workspaces" = {
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

      modules-center = [ "hyprland/window" ];
      "hyprland/window" = {
        format = " {title} ";
      };

      modules-right = [
        "pulseaudio"
        "custom/separator2"
        "network"
        "custom/separator3"
        "cpu"
        "memory"
        "custom/separator4"
        "clock"
        "custom/separator5"
        "custom/notification"
      ];
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
      "custom/separator2" = {
        format = "";
        tooltip = false;
      };
      network = {
        format-alt = "{ipaddr}/{cidr}";
        format-disconnected = "Disconnected ⚠ ";
        format-ethernet = "{ipaddr}/{cidr} 󰈀 ";
        format-linked = "{ifname} (No IP) ";
        format-wifi = "{essid} ({signalStrength}%)  ";
      };
      "custom/separator3" = {
        format = "";
        tooltip = false;
      };
      cpu = {
        format = "{usage}%  ";
        tooltip = false;
      };
      memory = {
        format = "{}%  ";
        tooltip = false;
      };
      "custom/separator4" = {
        format = "";
        tooltip = false;
      };
      clock = {
        format = "  {:%H:%M %m-%d-%Y}";
        tooltip = false;
      };
      "custom/separator5" = {
        format = "";
        tooltip = false;
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
