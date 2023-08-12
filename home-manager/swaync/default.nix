{ inputs, lib, config, pkgs, ... }: {
  home.packages = [
    pkgs.unstable.swaynotificationcenter
  ];

}
