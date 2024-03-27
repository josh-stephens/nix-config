{ inputs, darwin, lib, config, pkgs, ... }: {
  imports = [
    ./common.nix

    ./skhd
    ./borders
    ./aerospace
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
}
