let 
  system = "aarch64-darwin";
  user = "joshsymonds";
in { inputs, lib, config, pkgs, ... }: {
  homebrew = {
    enable = true;
    brews = [
    ];
    masApps = {
    };
  };
}
