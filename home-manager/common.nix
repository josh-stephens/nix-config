{ inputs, lib, config, pkgs, ... }: {
  # You can import other home-manager modules here
  imports = [
    # You can also split up your configuration and import pieces of it here:
    #./nvim
    ./git
    ./kitty
    ./k9s
    ./zsh
    ./starship
  ];

  home = {
    username = "joshsymonds";

    packages = with pkgs; [ 
      coreutils
      curl
      ripgrep
      ranger
      bat
      exa
      jq
      xdg-utils
      fzf
    ];
  };

  # Programs
  programs.go.enable = true;
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  programs.htop.enable = true;
  programs.htop.settings.show_program_path = true;

  xdg.enable = true;

  home.file."Backgrounds" = {
    source = ./Backgrounds;
    recursive = true;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.11";
}
