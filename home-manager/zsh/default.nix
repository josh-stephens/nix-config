{ inputs, lib, config, pkgs, ... }: {
  xdg.configFile."zsh" = {
    source = ./zsh;
    recursive = true;
  };

  programs.zsh = {
    package = pkgs.unstable.zsh;
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    enableSyntaxHighlighting = true;

    historySubstringSearch = {
      enable = true;
      searchDownKey = "j";
      searchUpKey = "k";
    };
    
    shellAliases = {
      ll = "exa -a -F -l -B --git";
      update = "sudo nixos-rebuild switch --flake \".#$(hostname)\"";
      vim = "nvim";
      vimdiff = "nvim -d"
    };

    envExtra = ''
      export NIX_CONFIG="experimental-features = nix-command flakes"
    '';

    history = {
      size = 50000;
      save = 50000;
      path = "${config.xdg.dataHome}/zsh/history";
    };

    initExtraFirst = ''
      source ${config.xdg.configHome}/zsh/extras/catppuccin_mocha-zsh-syntax-highlighting.zsh
    '';
  };
}

