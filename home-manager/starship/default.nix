{ inputs, lib, config, pkgs, ... }: {
  programs.starship = {
    package = pkgs.unstable.starship;
    enable = true;
    enableZshIntegration = true;

    settings = {
      palette = "catppuccin_mocha";

      format = "[](fg:lavender)$directory$character";

      right_format = "[](fg:rosewater)$cmd_duration[](fg:peach bg:rosewater)$git_branch$git_status[](bg:peach fg:blue)$aws[](bg:blue fg:teal)$kubernetes[](fg:teal)";

      add_newline = false;

      directory = {
        style = "bg:lavender fg:base";
        format = "[ $path ]($style)";
        fish_style_pwd_dir_length = 2;
        substitutions = {
          Documents = " ";
          Downloads = " ";
          Music = " ";
          Pictures = " ";
          Work = "󰃖 ";
          Personal = " ";
          Dropbox = " ";
        };
      };

      character = {
        success_symbol = "[](bg:green fg:lavender)[](fg:green)";
        error_symbol = "[](bg:red fg:lavender)[](fg:red)";
        vimcmd_symbol = "[](fg:yellow bg:lavender)[](bg:yellow fg:base)";
        vimcmd_replace_one_symbol = "[](fg:flamingo bg:lavender)[](bg:flamingo fg:base)";
        vimcmd_replace_symbol = "[](fg:flamingo bg:lavender)[](bg:flamingo fg:base)";
        vimcmd_visual_symbol = "[](fg:yellow bg:lavender)[](bg:yellow fg:base)";
      };

      "cmd_duration" = {
        style = "bg:rosewater fg:base";
        format = "[ $duration ]($style)";
      };

      "git_branch" = {
        symbol = "";
        style = "bg:peach fg:base";
        format = "[ $symbol $branch ]($style)";
      };

      "git_status" = {
        style = "bg:peach fg:base";
        format = "[$all_status$ahead_behind ]($style)";
      };

      kubernetes = {
        disabled = false;
        format = "[ $symbol$context ]($style)";
        style = "bg:teal fg:base";
      };

      aws = {
        format = "[ $symbol$profile ]($style)";
        style = "bg:blue fg:base";
      };

      palettes.catppuccin_mocha = {
        rosewater = "#f5e0dc";
        flamingo = "#f2cdcd";
        pink = "#f5c2e7";
        mauve = "#cba6f7";
        red = "#f38ba8";
        maroon = "#eba0ac";
        peach = "#fab387";
        yellow = "#f9e2af";
        green = "#a6e3a1";
        teal = "#94e2d5";
        sky = "#89dceb";
        sapphire = "#74c7ec";
        blue = "#89b4fa";
        lavender = "#b4befe";
        text = "#cdd6f4";
        subtext1 = "#bac2de";
        subtext0 = "#a6adc8";
        overlay2 = "#9399b2";
        overlay1 = "#7f849c";
        overlay0 = "#6c7086";
        surface2 = "#585b70";
        surface1 = "#45475a";
        surface0 = "#313244";
        base = "#1e1e2e";
        mantle = "#181825";
        crust = "#11111b";
      };
    };
  };
}
