{ inputs, lib, config, pkgs, ... }: {
  programs.starship = {
    package = pkgs.unstable.starship;
    enable = true;
    enableZshIntegration = true;

    settings = {
      palette = "catppuccin_mocha";

      format = ''
        [](fg:mauve)\
        $directory\
        $character\
      '';

      right_format = ''
      [](bg:#1E1E2E)\
        $git_branch\
        $git_status\
      []()\
      []()\
      '';

      add_newline = false;

      directory = {
        style = "bg:mauve";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        fish_style_pwd_dir_length = 1;
        substitutions = {
          Documents = " "; 
          Downloads = " ";
          Music = " ";
          Pictures = " ";
          Work = ""
        };
      };

      character = {
        success_symbol = "[](bg:#f38ba8 fg:mauve)[ ](bg:green)[](fg:green) ";
        error_symbol = "[](bg:#a6e3a1 fg:mauve)[ ](bg:red)[](fg:red) ";
        vimcmd_symbol = "[](bg:#f38ba8 fg:mauve)[ ](bg:green)[](fg:green) ";
        vimcmd_replace_one_symbol = "[](bg:lavender fg:mauve)[ ](bg:lavender)[](fg:lavender) ";
        vimcmd_replace_symbol = "[](bg:lavender fg:mauve)[ ](bg:lavender)[](fg:lavender) ";
        vimcmd_visual_symbol = "[](bg:yellow fg:mauve)[ ](bg:yellow)[](fg:yellow) ";
      };

      palettes.catppuccin_mocha .= {
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
