{ inputs, lib, config, pkgs, ... }: {
  home.packages = [ pkgs.unstable.k9s ];

  xdg.configFile."k9s" = {
    source = ./k9s;
    recursive = true;
  };
}
