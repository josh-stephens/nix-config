{ inputs, darwin, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix

    ./yabai
    ./skhd
    ./sketchybar
  ];

  home = {
    homeDirectory = "/Users/joshsymonds";

    packages = with pkgs; [
      pkgs.python3
    ];
  };

  programs.zsh.shellAliases.update = "darwin-rebuild switch --flake \".#$(hostname -s)\"";
}
