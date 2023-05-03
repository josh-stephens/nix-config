{ inputs, lib, config, pkgs, ... }: {
  xdg.configFile."zsh" = {
    source = ./zsh;
    recursive = true;
  };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    enableSyntaxHighlighting = true;

    historySubstringSearch = {
      enable = true;
    };
    
    shellAliases = {
      ll = "exa -a -F -l -B --git";
      ls = "ls --color=auto";
      update = "sudo nixos-rebuild switch --flake \".#$(hostname)\"";
      vim = "nvim";
      vimdiff = "nvim -d";
    };

    envExtra = ''
      export NIX_CONFIG="experimental-features = nix-command flakes"
      export LS_COLORS="$(vivid generate catppuccin-mocha)"
    '';

    history = {
      size = 50000;
      save = 50000;
      path = "${config.xdg.dataHome}/zsh/history";
    };

    initExtraFirst = ''
      source ${config.xdg.configHome}/zsh/extras/catppuccin_mocha-zsh-syntax-highlighting.zsh
    '';
    initExtra = ''
      if [ -n "$\{commands[fzf-share]}" ]; then
        source "$(fzf-share)/key-bindings.zsh"
        source "$(fzf-share)/completion.zsh"
      fi
    '';
  };
}

