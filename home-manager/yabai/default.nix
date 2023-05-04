{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ../../modules/services/yabai.nix
  ];

  services.yabai = {
    enable = true;
    package = pkgs.unstable.yabai;

    signals = {
      dock_did_restart = "sudo yabai --load-sa";
      window_focused = "sketchybar --trigger window_focus";
    };

    config = {
      external_bar = "all:49:0";
      window_border = "on";
      mouse_follows_focus = "off";
      window_placement = "second_child";
      window_topmost = "off";
      window_shadow = "float";
      window_opacity = "off";
      window_opacity_duration = "0.0";
      active_window_opacity = "1.0";
      normal_window_opacity = "1.0";
      window_border_width = "4";
      window_border_color = "0xffe1e3e4";
      insert_feedback_color = "0xffe1e3e4";
      split_ratio = "0.50";
      auto_balance = "off";
      mouse_modifier = "fn";
      mouse_action1 = "move";
      mouse_action2 = "resize";
      mouse_drop_action = "swap";
      layout = "bsp";
      top_padding = "11";
      bottom_padding = "11";
      left_padding = "11";
      right_padding = "11";
      window_gap = "11";
    };

    extraConfig = ''
      yabai -m rule --add app="^(LuLu|Vimac|Calculator|VLC|System Preferences|zoom.us|Photo Booth|Archive Utility|Python|LibreOffice)$" manage=off

# ===== Rules ==================================

      yabai -m rule --add label="Steam" app="^Steam$" manage=off
      yabai -m rule --add label="Finder" app="^Finder$" title="(Co(py|nnect)|Move|Info|Pref)" manage=off
      yabai -m rule --add label="Alfred" app="^Alfred$" manage=off
      yabai -m rule --add label="Safari" app="^Safari$" title="^(General|(Tab|Password|Website|Extension)s|AutoFill|Se(arch|curity)|Privacy|Advance)$" manage=off
      yabai -m rule --add label="System Preferences" app="^System Preferences$" manage=off
      yabai -m rule --add label="App Store" app="^App Store$" manage=off
      yabai -m rule --add label="Activity Monitor" app="^Activity Monitor$" manage=off
      yabai -m rule --add label="Calculator" app="^Calculator$" manage=off
      yabai -m rule --add label="Dictionary" app="^Dictionary$" manage=off
      yabai -m rule --add label="Software Update" title="Software Update" manage=off
      yabai -m rule --add label="About This Mac" app="System Information" title="About This Mac" manage=off
      yabai -m rule --add label="Select file to save to" app="^Inkscape$" title="Select file to save to" manage=off

      yabai -m space 1 --label code
      yabai -m space 2 --label web
      yabai -m space 3 --label idle
      yabai -m space 4 --label misc
      yabai -m space 5 --label doc
      yabai -m space 6 --label help
      yabai -m space 7 --label music

      echo "yabai configuration loaded.."
    '';
  };
}
