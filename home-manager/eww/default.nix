{ inputs, lib, config, pkgs, ... }: {
  home.packages = with pkgs.unstable; [
    coreutils-full
    jq
    socat
  ];

  programs.eww = {
    enable = true;
    package = pkgs.unstable.eww-wayland;
    configDir = ./eww;
  };
}
