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
    historySubstringSearch.enable = true;
    
    shellAliases = {
      ll = "exa -a -F -l -B --git";
      ls = "ls --color=auto";
      vim = "nvim";
      vimdiff = "nvim -d";
    };

    envExtra = ''
      export NIX_CONFIG="experimental-features = nix-command flakes"
      export LS_COLORS="$(vivid generate catppuccin-mocha)"
      export ZVM_CURSOR_STYLE_ENABLED=false
    '';

    history = {
      size = 50000;
      save = 50000;
      path = "${config.xdg.dataHome}/zsh/history";
    };

    initExtraFirst = ''
    '';
    initExtra = ''
      if [ -n "$\{commands[fzf-share]}" ]; then
        source "$(fzf-share)/key-bindings.zsh"
        source "$(fzf-share)/completion.zsh"
      fi

      source ${pkgs.unstable.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
    '';
  };
}

