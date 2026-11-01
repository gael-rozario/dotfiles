# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

eval "$(starship init zsh)"

setopt histignoredups sharehistory hist_expire_dups_first hist_verify


# Keep history within the shell and save it to ~/.zsh_history:
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

export PATH="$PATH:/opt/nvim/bin"
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null; then
  eval "$(pyenv init -)"
  pyenv commands 2>/dev/null | grep -qx virtualenv-init && eval "$(pyenv virtualenv-init -)"
fi

export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:~/.local/bin
export PATH=$PATH:~/go/bin

# source ~/zsh/powerlevel10k/powerlevel10k.zsh-theme

autoload -U history-search-end

bindkey -v
export KEYTIMEOUT=1

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
source ~/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/zsh/zsh-history-substring-search/zsh-history-substring-search.zsh

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
# j/k move between lines of a multi-line command; fall back to history search on the first/last line
_vi_up_line_or_substring_search() {
  if [[ $LBUFFER == *$'\n'* ]]; then zle up-line
  else zle history-substring-search-up; fi
}
_vi_down_line_or_substring_search() {
  if [[ $RBUFFER == *$'\n'* ]]; then zle down-line
  else zle history-substring-search-down; fi
}
zle -N _vi_up_line_or_substring_search
zle -N _vi_down_line_or_substring_search
bindkey -M vicmd 'k' _vi_up_line_or_substring_search
bindkey -M vicmd 'j' _vi_down_line_or_substring_search

[ -f "$HOME/zsh/aliasrc" ] && source "$HOME/zsh/aliasrc"

# -- Use fd instead of find for fzf (Debian/Ubuntu ship it as fdfind) --
if command -v fd >/dev/null; then _fd=fd
elif command -v fdfind >/dev/null; then _fd=fdfind
fi
if [[ -n $_fd ]]; then
  export FZF_DEFAULT_COMMAND="$_fd --hidden --strip-cwd-prefix --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="$_fd --type=d --hidden --strip-cwd-prefix --exclude .git"

  # Use fd for listing path candidates ($1 is the base path to start traversal).
  _fzf_compgen_path() {
    $_fd --hidden --exclude .git . "$1"
  }

  # Use fd to generate the list for directory completion
  _fzf_compgen_dir() {
    $_fd --type=d --hidden --exclude .git . "$1"
  }
fi

# Yazi setup
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

eval "$(zoxide init zsh)"
export _ZO_DOCTOR=0

# Remap caps lock to ctrl (X11 only)
[[ -n $DISPLAY ]] && command -v setxkbmap >/dev/null && setxkbmap -option "ctrl:nocaps"

# fzf
[[ -d $HOME/.fzf/bin ]] && export PATH="$HOME/.fzf/bin:$PATH"
command -v fzf >/dev/null && eval "$(fzf --zsh)"

# sdkman config
[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ] && source "$HOME/.sdkman/bin/sdkman-init.sh"


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
export PATH="$HOME/.tfenv/bin:$PATH"

# custom env variables
[ -f ~/.zsh/export.sh ] && source ~/.zsh/export.sh

# Secrets live only on the machine, never in this repo
[ -f ~/zsh/.lab.key ] && source ~/zsh/.lab.key   # homelab
[ -f ~/zsh/.llm.key ] && source ~/zsh/.llm.key   # llm

export KUBECONFIG=$HOME/.kube/config
export KUBE_CONFIG_PATH=$KUBECONFIG

# opencode
export PATH=$HOME/.opencode/bin:$PATH
