# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

setopt histignoredups sharehistory hist_expire_dups_first hist_verify


# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history

export PATH="$PATH:/opt/nvim/bin"
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:~/.local/bin

source ~/zsh/powerlevel10k/powerlevel10k.zsh-theme

autoload -U history-search-end
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-up


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
source ~/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/zsh/zsh-history-substring-search/zsh-history-substring-search.zsh

[ -f "$HOME/zsh/aliasrc" ] && source "$HOME/zsh/aliasrc"

eval "$(zoxide init zsh)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
