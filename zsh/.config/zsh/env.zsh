# ============================================================
# General environment
# ============================================================

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

export EDITOR="vim"
export VISUAL="$EDITOR"
export PAGER="less"
export LESS="-R"
export MANPAGER="bat --language=man --style=plain"

# Keep PATH entries unique while preserving order.
typeset -U path PATH

path=(
  "$HOME/.cargo/bin"
  "$HOME/.local/bin"
  "$HOME/bin"
  "$HOME/go/bin"
  $path
)

# ============================================================
# Zsh history
# ============================================================

HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

setopt EXTENDED_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
