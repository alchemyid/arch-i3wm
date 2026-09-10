# Created by newuser for 5.9.2
if [[ -n "$DISPLAY" ]]; then
    PROMPT='%F{blue}%~%f%F{yellow}${vcs_info_msg_0_}%f %F{green}❯%f '
else
    PROMPT="%F{blue}%~%f %F{green}%f "
fi

#remote nerdctl command
nerdctl() {
    ssh -t me@labs.alche.my.id "nerdctl $*"
}

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

# Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select

# Plugins
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Prompt - simple, no icons needed, fast to render
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST

#PROMPT='%F{blue}%~%f%F{yellow}${vcs_info_msg_0_}%f %F{green}❯%f '

# Aliases
alias ll='ls -lah'
alias k='kubectl'
alias tf='terraform'
alias vim='nvim'
alias startx='startx > /dev/null 2>&1'
# Editor
export EDITOR=vim
export VISUAL=vim

# Paths (Cargo / Rust & Go)
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"
[[ -d "$HOME/go/bin" ]] && export PATH="$HOME/go/bin:$PATH"
