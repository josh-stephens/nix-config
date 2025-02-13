{ inputs, lib, config, pkgs, ... }: {
  home.packages = with pkgs.unstable; [
    nodejs_20
    ripgrep
    fd
    rustc
    cargo
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    package = pkgs.unstable.neovim-unwrapped;
  };

  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };
}
