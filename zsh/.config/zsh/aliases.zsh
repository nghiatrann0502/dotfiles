# ============================================================
# Navigation and files
# ============================================================

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias ls='eza --icons=auto --group-directories-first'
alias ll='eza -lah --icons=auto --git --group-directories-first'
alias la='eza -a --icons=auto --group-directories-first'
alias lt='eza --tree --level=2 --icons=auto'
alias lta='eza --tree --level=3 --icons=auto --all'

# Keep native cat intact; use b/bp when you want bat.
alias b='bat'
alias bp='bat --style=plain --paging=never'

alias c='clear'
alias reload='exec zsh'
alias path='printf "%s\n" "${path[@]}"'
alias ports='lsof -nP -iTCP -sTCP:LISTEN'

# ============================================================
# Git
# ============================================================

alias g='git'
alias gs='git status'
alias gd='git diff'
alias gl='git log --graph --decorate --oneline --all'
alias lg='lazygit'

# ============================================================
# Docker
# ============================================================

alias d='docker'
alias dc='docker compose'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dcu='docker compose up'
alias dcud='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'

# ============================================================
# tmux
# ============================================================

alias ta='tmux attach'
alias tls='tmux list-sessions'
alias tdev='tmux new-session -A -s dev'
