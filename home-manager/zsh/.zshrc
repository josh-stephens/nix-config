# shortcut to this dotfiles path is $ZSH
export ZSH=${XDG_DATA_HOME:-${HOME}}/.config/zsh

if [ -f "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  export PATH="/opt/homebrew/opt/grep/libexec/gnubin:${PATH}"
fi

# all of our zsh files
typeset -U config_files
config_files=($ZSH/**/*.zsh)

# load the path files
for file in ${(M)config_files:#*/path.zsh}
do
  . $file
done

# load everything but the path and completion files
for file in ${${config_files:#*/path.zsh}:#*/completion.zsh}
do
  . $file
done

# load every completion after autocomplete loads
for file in ${(M)config_files:#*/completion.zsh}
do
  . $file
done

unset config_files

# zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
  zdharma-continuum/zinit-annex-as-monitor \
  zdharma-continuum/zinit-annex-bin-gem-node \
  zdharma-continuum/zinit-annex-patch-dl \
  zdharma-continuum/zinit-annex-rust \
  NICHOLAS85/z-a-linkbin

zinit ice wait"0b" lucid blockf atpull'zinit creinstall -q .'
zinit light zsh-users/zsh-completions

# Syntax
zinit wait lucid for \
 atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
 blockf \
    zsh-users/zsh-completions \
 atload"!_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions

zi ice atclone"dircolors -b LS_COLORS > c.zsh" atpull'%atclone' pick"c.zsh" nocompile'!'
zi light trapd00r/LS_COLORS

# zsh-autosuggestions
zinit ice wait lucid atload"!_zsh_autosuggest_start"
zinit load zsh-users/zsh-autosuggestions

zstyle ":history-search-multi-word" page-size "11"
zinit ice wait"1" lucid
zinit load zdharma-continuum/history-search-multi-word

zi for \
  https://github.com/junegunn/fzf/raw/master/shell/{'completion','key-bindings'}.zsh

zinit light geometry-zsh/geometry

### End of Zinit's installer chunk
