{ inputs, lib, config, pkgs, ... }: {
  home.packages = with pkgs; [
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
    package = inputs.neovim-nightly.packages.${pkgs.system}.default;
  };

  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };
}
