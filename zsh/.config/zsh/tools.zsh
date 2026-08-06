# ============================================================
# fzf shell bindings
# ============================================================

if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# Atuin is loaded after fzf so Ctrl-R belongs to Atuin.
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh --disable-up-arrow --disable-ai)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Use a popup for fuzzy Tab completion while inside tmux.
if [[ -n "${TMUX:-}" ]] && (( $+commands[ftb-tmux-popup] )); then
  zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
fi

# Accept one suggested word with Option-F.
bindkey '^[f' forward-word
