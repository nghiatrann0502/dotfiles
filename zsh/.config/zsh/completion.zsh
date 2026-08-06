# ============================================================
# Native Zsh completion
# ============================================================

zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$HOME/.cache/zsh"
zstyle ':completion:*' menu no
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*'

# ============================================================
# fzf
# Atuin owns Ctrl-R. fzf keeps Ctrl-T and Option-C.
# ============================================================

export FZF_DEFAULT_COMMAND='fd --type f --type l --hidden --follow --exclude .git --exclude node_modules --exclude .dart_tool --exclude build'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git --exclude node_modules --exclude .dart_tool --exclude build'

export FZF_DEFAULT_OPTS='--height=45% --layout=reverse --border --info=inline --cycle --preview-window=right:55%:wrap'

export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || eza --tree --level=2 --icons=auto --color=always {} 2>/dev/null'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons=auto --color=always {} 2>/dev/null | head -200'"

# fzf-tab presentation.
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons=auto --color=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --icons=auto --color=always $realpath'
