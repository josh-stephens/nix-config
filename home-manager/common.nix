{ inputs, lib, config, pkgs, ... }:
let
  # Short alias for pkgs.unstable
  u = pkgs.unstable;

  # Overridden aider derivation
  aiderWithBoto3 = u.aider-chat.overridePythonAttrs (oldAttrs: {
    dependencies = oldAttrs.dependencies ++ [
      u.python3.pkgs.boto3
    ];
  });
in
{
  # You can import other home-manager modules here
  imports = [
    # You can also split up your configuration and import pieces of it here:
    ./atuin
    ./kitty
    ./nvim
    ./git
    ./k9s
    ./zsh
    ./starship
    ./lazygit
  ];

  home = {
    enableNixpkgsReleaseCheck = false;
    username = "joshsymonds";

    packages = with u; [
      coreutils-full
      curl
      ripgrep
      ranger
      bat
      jq
      killall
      eza
      xdg-utils
      ncdu
      fzf
      vivid
      manix
      talosctl
      wget
      go-tools
      socat
      wireguard-tools
      k9s
      aiderWithBoto3
    ];
  };

  # Programs
  programs.go = {
    enable = true;
    package = pkgs.unstable.go_1_23;
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
  home.stateVersion = "25.05";
}
