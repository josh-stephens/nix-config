{ inputs, lib, config, pkgs, ... }: {
  homebrew = {
    enable = true;
    autoUpdate = true;
    brews = [

    ];
    masApps = {
      "1Password" = 1107421413;
      Xcode = 497799835;
    };
  };
}
