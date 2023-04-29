(( $+commands[exa] )) && alias ll='exa -a -F -l -B --git'

(( $+commands[nvim] )) && alias vim="nvim"
(( $+commands[nvim] )) && alias vimdiff="nvim -d"

alias rebuild="sudo nixos-rebuild switch --flake \".#$(hostname)\""
