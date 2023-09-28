{ inputs, lib, config, pkgs, ... }: {
  # You can import other home-manager modules here
  imports = [
    # You can also split up your configuration and import pieces of it here:
    ./kitty
    ./nvim
    ./git
    ./k9s
    ./zsh
    ./starship
  ];

  home = {
    username = "joshsymonds";

    packages = with pkgs.unstable; [
      coreutils-full
      curl
      ripgrep
      ranger
      bat
      jq
      killall
      eza
      xdg-utils
      fzf
      vivid
      manix
      talosctl
      wget
      go-tools
      socat
      wireguard-tools
    ];
  };

  # Programs
  programs.go = {
    enable = true;
    package = pkgs.unstable.go_1_20;
  };
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  programs.htop = {
    enable = true;
    package = pkgs.unstable.htop;
    settings.show_program_path = true;
  };
  xdg.enable = true;

  home.file."Backgrounds" = {
    source = ./Backgrounds;
    recursive = true;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
