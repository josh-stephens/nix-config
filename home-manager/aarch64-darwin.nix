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
      pkgs.unstable.k9s
    ];
  };

  programs.zsh.shellAliases.update = "darwin-rebuild switch --flake \".#$(hostname -s)\"";
  programs.kitty.font.size = 13;
  programs.kitty.settings."kitty_mod" = "alt";
}
